#import "Messages.h"
#include "erl_nif.h"
#import <Foundation/Foundation.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <objc/runtime.h>

// Helper function to convert NSString to ERL_NIF_TERM
static ERL_NIF_TERM make_string(ErlNifEnv* env, NSString* str)
{
    const char* utf8Str = [str UTF8String];
    ERL_NIF_TERM binary;
    unsigned char* buff = enif_make_new_binary(env, strlen(utf8Str), &binary);
    memcpy(buff, utf8Str, strlen(utf8Str));
    return binary;
}

// Helper function to create error tuple
static ERL_NIF_TERM make_error(ErlNifEnv* env, NSString* message)
{
    return enif_make_tuple2(env,
        enif_make_atom(env, "error"),
        make_string(env, message));
}

// Helper function to convert binary to NSString
static NSString* binary_to_string(ErlNifBinary bin)
{
    return [[NSString alloc] initWithBytes:bin.data
                                    length:bin.size
                                  encoding:NSUTF8StringEncoding];
}

// Helper function to initialize Messages app
static MessagesApplication* init_messages(ErlNifEnv* env, ERL_NIF_TERM* error)
{
    MessagesApplication* messages = [SBApplication applicationWithBundleIdentifier:@"com.apple.MobileSMS"];

    if (!messages) {
        *error = make_error(env, @"Could not connect to Messages.app");
        return nil;
    }

    if (![messages isRunning]) {
        *error = make_error(env, @"Messages application is not running");
        return nil;
    }

    return messages;
}

// Helper function to find participant
static MessagesParticipant* find_participant(MessagesApplication* messages, NSString* recipient, ErlNifEnv* env, ERL_NIF_TERM* error)
{
    MessagesParticipant* participant = [[messages participants] objectWithName:recipient];
    if (!participant) {
        *error = make_error(env, @"Could not find recipient. Have they messaged you before?");
        return nil;
    }
    return participant;
}

// Helper function to find chat
static MessagesChat* find_chat(MessagesApplication* messages, NSString* chatId, ErlNifEnv* env, ERL_NIF_TERM* error)
{
    MessagesChat* chat = [[messages chats] objectWithID:chatId];
    if (!chat) {
        *error = make_error(env, @"Chat not found");
        return nil;
    }
    return chat;
}

static ERL_NIF_TERM send_message_to_buddy(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary message_bin, recipient_bin;
    ERL_NIF_TERM error;

    if (!enif_inspect_binary(env, argv[0], &message_bin) || !enif_inspect_binary(env, argv[1], &recipient_bin)) {
        return make_error(env, @"Invalid arguments.");
    }

    @autoreleasepool {
        NSString* message = binary_to_string(message_bin);
        NSString* recipient = binary_to_string(recipient_bin);

        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        MessagesParticipant* participant = find_participant(messages, recipient, env, &error);
        if (!participant)
            return error;

        @try {
            [messages send:message to:participant];
            return enif_make_atom(env, "ok");
        } @catch (NSException* exception) {
            return make_error(env, [exception reason]);
        }
    }
}

static ERL_NIF_TERM send_message_to_chat(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary message_bin, chat_id_bin;
    ERL_NIF_TERM error;

    if (!enif_inspect_binary(env, argv[0], &message_bin) || !enif_inspect_binary(env, argv[1], &chat_id_bin)) {
        return make_error(env, @"Invalid arguments.");
    }

    @autoreleasepool {
        NSString* message = binary_to_string(message_bin);
        NSString* chatId = binary_to_string(chat_id_bin);

        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        MessagesChat* chat = find_chat(messages, chatId, env, &error);
        if (!chat)
            return error;

        @try {
            [messages send:message to:chat];
            return enif_make_atom(env, "ok");
        } @catch (NSException* exception) {
            return make_error(env, [exception reason]);
        }
    }
}

// Helper function to create a list result
static ERL_NIF_TERM make_list_result(ErlNifEnv* env, ERL_NIF_TERM list)
{
    return enif_make_tuple2(env, enif_make_atom(env, "ok"), list);
}

// Helper function to allocate terms array
static ERL_NIF_TERM* allocate_terms(ErlNifEnv* env, unsigned int count, ERL_NIF_TERM* error)
{
    ERL_NIF_TERM* terms = enif_alloc(sizeof(ERL_NIF_TERM) * count);
    if (!terms) {
        *error = make_error(env, @"Memory allocation failed");
        return nil;
    }
    return terms;
}

static ERL_NIF_TERM list_chats(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    @autoreleasepool {
        ERL_NIF_TERM error;
        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        NSArray* chats = [messages valueForKey:@"chats"];
        if (!chats) {
            return make_list_result(env, enif_make_list(env, 0));
        }

        NSMutableArray* chatList = [NSMutableArray array];

        for (id chat in chats) {
            @try {
                NSString* chatId = [chat valueForKey:@"id"];
                if (!chatId)
                    continue;

                NSString* chatName = [chat valueForKey:@"name"] ?: @"";
                NSArray* participants = [chat valueForKey:@"participants"] ?: @[];

                NSMutableArray* handles = [NSMutableArray array];
                for (id participant in participants) {
                    NSString* handle = [participant valueForKey:@"handle"];
                    if (handle) {
                        [handles addObject:handle];
                    }
                }

                [chatList addObject:@ {
                    @"id" : chatId,
                    @"name" : chatName,
                    @"participants" : handles
                }];
            } @catch (NSException* exception) {
                continue;
            }
        }

        unsigned int numChats = [chatList count];
        ERL_NIF_TERM* terms = allocate_terms(env, numChats, &error);
        if (!terms)
            return error;

        for (unsigned int i = 0; i < numChats; i++) {
            NSDictionary* chat = chatList[i];
            ERL_NIF_TERM mapTerm = enif_make_new_map(env);

            // Add id
            enif_make_map_put(env, mapTerm,
                enif_make_atom(env, "id"),
                make_string(env, chat[@"id"]),
                &mapTerm);

            // Add name
            enif_make_map_put(env, mapTerm,
                enif_make_atom(env, "name"),
                make_string(env, chat[@"name"]),
                &mapTerm);

            // Add participants
            NSArray* participants = chat[@"participants"];
            ERL_NIF_TERM* participantTerms = allocate_terms(env, [participants count], &error);
            if (participantTerms) {
                for (unsigned int j = 0; j < [participants count]; j++) {
                    participantTerms[j] = make_string(env, participants[j]);
                }
                ERL_NIF_TERM participantList = enif_make_list_from_array(env,
                    participantTerms,
                    [participants count]);
                enif_make_map_put(env, mapTerm,
                    enif_make_atom(env, "participants"),
                    participantList,
                    &mapTerm);
                enif_free(participantTerms);
            }

            terms[i] = mapTerm;
        }

        ERL_NIF_TERM result = enif_make_list_from_array(env, terms, numChats);
        enif_free(terms);

        return make_list_result(env, result);
    }
}

static ERL_NIF_TERM list_buddies(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    @autoreleasepool {
        ERL_NIF_TERM error;
        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        NSArray* participants = [messages participants];
        if (!participants) {
            return make_list_result(env, enif_make_list(env, 0));
        }

        NSMutableArray* buddyList = [NSMutableArray array];
        for (id buddy in participants) {
            @try {
                [buddyList addObject:@ { @"handle" : [buddy handle] }];
            } @catch (NSException* exception) {
                continue;
            }
        }

        unsigned int numBuddies = [buddyList count];
        ERL_NIF_TERM* terms = allocate_terms(env, numBuddies, &error);
        if (!terms)
            return error;

        for (unsigned int i = 0; i < numBuddies; i++) {
            NSDictionary* buddy = buddyList[i];
            ERL_NIF_TERM mapTerm = enif_make_new_map(env);

            ERL_NIF_TERM nameTerm = make_string(env, buddy[@"handle"]);
            enif_make_map_put(env, mapTerm,
                enif_make_atom(env, "handle"),
                nameTerm,
                &mapTerm);

            terms[i] = mapTerm;
        }

        ERL_NIF_TERM result = enif_make_list_from_array(env, terms, numBuddies);
        enif_free(terms);

        return make_list_result(env, result);
    }
}

static ERL_NIF_TERM send_file_to_buddy(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary file_path_bin, recipient_bin;
    ERL_NIF_TERM error;

    if (!enif_inspect_binary(env, argv[0], &file_path_bin) || !enif_inspect_binary(env, argv[1], &recipient_bin)) {
        return make_error(env, @"Invalid arguments.");
    }

    @autoreleasepool {
        NSString* filePath = binary_to_string(file_path_bin);
        NSString* recipient = binary_to_string(recipient_bin);

        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        // Check if file exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            return make_error(env, @"File does not exist");
        }

        MessagesParticipant* participant = find_participant(messages, recipient, env, &error);
        if (!participant)
            return error;

        @try {
            NSURL* fileURL = [NSURL fileURLWithPath:filePath];
            [messages send:fileURL to:participant];
            return enif_make_atom(env, "ok");
        } @catch (NSException* exception) {
            return make_error(env, [exception reason]);
        }
    }
}

static ERL_NIF_TERM send_file_to_chat(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary file_path_bin, recipient_bin;
    ERL_NIF_TERM error;

    if (!enif_inspect_binary(env, argv[0], &file_path_bin) || !enif_inspect_binary(env, argv[1], &recipient_bin)) {
        return make_error(env, @"Invalid arguments.");
    }

    @autoreleasepool {
        NSString* filePath = binary_to_string(file_path_bin);
        NSString* recipient = binary_to_string(recipient_bin);

        MessagesApplication* messages = init_messages(env, &error);
        if (!messages)
            return error;

        // Check if file exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            return make_error(env, @"File does not exist");
        }

        MessagesChat* chat = find_chat(messages, recipient, env, &error);
        if (!chat)
            return error;

        @try {
            NSURL* fileURL = [NSURL fileURLWithPath:filePath];
            [messages send:fileURL to:chat];
            return enif_make_atom(env, "ok");
        } @catch (NSException* exception) {
            return make_error(env, [exception reason]);
        }
    }
}

static ErlNifFunc nif_funcs[] = {
    { "send_message_to_buddy", 2, send_message_to_buddy },
    { "send_message_to_chat", 2, send_message_to_chat },
    { "send_file_to_buddy", 2, send_file_to_buddy },
    { "send_file_to_chat", 2, send_file_to_chat },
    { "list_chats", 0, list_chats },
    { "list_buddies", 0, list_buddies },
};

ERL_NIF_INIT(Elixir.Imessaged.Native, nif_funcs, NULL, NULL, NULL, NULL)