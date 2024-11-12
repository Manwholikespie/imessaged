#include "erl_nif.h"
#import <Foundation/Foundation.h>
#import <ScriptingBridge/ScriptingBridge.h>

// Define the Messages application interface
@interface MessagesApplication : SBApplication
- (id)send:(id)text to:(id)recipient;
@property (readonly) NSArray *participants;
@property (readonly) NSArray *accounts;
@property (readonly) NSArray *chats;
@end

@interface MessagesChat : NSObject
@property (readonly) NSString *id;
@property (readonly) NSString *name;
@property (readonly) NSArray *participants;
@end

// Helper function to convert NSString to ERL_NIF_TERM
static ERL_NIF_TERM make_string(ErlNifEnv* env, NSString* str) {
    const char* utf8Str = [str UTF8String];
    ERL_NIF_TERM binary;
    unsigned char* buff = enif_make_new_binary(env, strlen(utf8Str), &binary);
    memcpy(buff, utf8Str, strlen(utf8Str));
    return binary;
}

static ERL_NIF_TERM send_message(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary message_bin, recipient_bin;
    
    if (!enif_inspect_binary(env, argv[0], &message_bin) ||
        !enif_inspect_binary(env, argv[1], &recipient_bin)) {
        return enif_make_atom(env, "error");
    }

    @autoreleasepool {
        NSString* message = [[NSString alloc] initWithBytes:message_bin.data
                                                   length:message_bin.size
                                                 encoding:NSUTF8StringEncoding];
        
        NSString* recipient = [[NSString alloc] initWithBytes:recipient_bin.data
                                                     length:recipient_bin.size
                                                   encoding:NSUTF8StringEncoding];

        MessagesApplication* messages = [SBApplication applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
        
        if (!messages) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, @"Could not connect to Messages.app"));
        }

        // First try to find an existing participant
        id participants = [messages valueForKey:@"participants"];
        id participant = nil;
        
        for (id p in participants) {
            NSString* handle = [p handle];
            // Check for both the exact handle and normalized forms
            if ([handle isEqualToString:recipient] ||
                [handle.lowercaseString isEqualToString:recipient.lowercaseString]) {
                participant = p;
                break;
            }
        }

        // If no participant found, we need to determine if this is an iMessage account
        if (!participant) {
            // Check if the recipient looks like an email
            if ([recipient containsString:@"@"]) {
                // Look for an iMessage account
                NSArray* accounts = [messages valueForKey:@"accounts"];
                BOOL hasIMessage = NO;
                
                for (id account in accounts) {
                    NSString* serviceType = [account valueForKey:@"serviceType"];
                    if ([serviceType isEqualToString:@"iMessage"]) {
                        hasIMessage = YES;
                        break;
                    }
                }
                
                if (!hasIMessage) {
                    return enif_make_tuple2(env,
                                          enif_make_atom(env, "error"),
                                          make_string(env, @"No iMessage account available"));
                }
            }
        }

        // Send the message
        @try {
            if (participant) {
                [messages send:message to:participant];
            } else {
                // Create a new conversation
                // Note: Messages.app will validate if the recipient is valid
                [messages send:message to:recipient];
            }
            return enif_make_atom(env, "ok");
        } @catch (NSException *exception) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, [exception reason]));
        }
    }
}

static ERL_NIF_TERM send_to_chat(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary message_bin, chat_id_bin;
    
    if (!enif_inspect_binary(env, argv[0], &message_bin) ||
        !enif_inspect_binary(env, argv[1], &chat_id_bin)) {
        return enif_make_atom(env, "error");
    }

    @autoreleasepool {
        NSString* message = [[NSString alloc] initWithBytes:message_bin.data
                                                   length:message_bin.size
                                                 encoding:NSUTF8StringEncoding];
        
        NSString* chatId = [[NSString alloc] initWithBytes:chat_id_bin.data
                                                  length:chat_id_bin.size
                                                encoding:NSUTF8StringEncoding];

        MessagesApplication* messages = [SBApplication applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
        
        if (!messages) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, @"Could not connect to Messages.app"));
        }

        // Find the chat by ID
        NSArray* chats = [messages valueForKey:@"chats"];
        MessagesChat* targetChat = nil;
        
        for (MessagesChat* chat in chats) {
            if ([[chat valueForKey:@"id"] isEqualToString:chatId]) {
                targetChat = chat;
                break;
            }
        }
        
        if (!targetChat) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, @"Chat not found"));
        }

        // Send the message
        @try {
            [messages send:message to:targetChat];
            return enif_make_atom(env, "ok");
        } @catch (NSException *exception) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, [exception reason]));
        }
    }
}

static ERL_NIF_TERM list_chats(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    @autoreleasepool {
        MessagesApplication* messages = [SBApplication applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
        
        if (!messages) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, @"Could not connect to Messages.app"));
        }

        NSArray* chats = [messages valueForKey:@"chats"];
        if (!chats) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "ok"),
                                  enif_make_list(env, 0));
        }

        NSMutableArray* chatList = [NSMutableArray array];
        
        for (id chat in chats) {
            @try {
                NSString* chatId = [chat valueForKey:@"id"];
                if (!chatId) continue;
                
                NSString* chatName = [chat valueForKey:@"name"];
                if (!chatName) chatName = @"";
                
                NSArray* participants = [chat valueForKey:@"participants"];
                if (!participants) participants = @[];
                
                NSMutableArray* handles = [NSMutableArray array];
                for (id participant in participants) {
                    NSString* handle = [participant valueForKey:@"handle"];
                    if (handle) {
                        [handles addObject:handle];
                    }
                }
                
                [chatList addObject:@{
                    @"id": chatId,
                    @"name": chatName,
                    @"participants": handles
                }];
            } @catch (NSException* exception) {
                // Skip any problematic chats
                continue;
            }
        }
        
        // Convert the NSArray of chat dictionaries to Erlang terms
        unsigned int numChats = [chatList count];
        ERL_NIF_TERM* terms = enif_alloc(sizeof(ERL_NIF_TERM) * numChats);
        if (!terms) {
            return enif_make_tuple2(env,
                                  enif_make_atom(env, "error"),
                                  make_string(env, @"Memory allocation failed"));
        }
        
        for (unsigned int i = 0; i < numChats; i++) {
            NSDictionary* chat = chatList[i];
            ERL_NIF_TERM mapTerm = enif_make_new_map(env);
            
            // Add id
            ERL_NIF_TERM idTerm = make_string(env, chat[@"id"]);
            enif_make_map_put(env, mapTerm, 
                            enif_make_atom(env, "id"), 
                            idTerm, 
                            &mapTerm);
            
            // Add name
            ERL_NIF_TERM nameTerm = make_string(env, chat[@"name"]);
            enif_make_map_put(env, mapTerm, 
                            enif_make_atom(env, "name"), 
                            nameTerm, 
                            &mapTerm);
            
            // Add participants
            NSArray* participants = chat[@"participants"];
            ERL_NIF_TERM* participantTerms = enif_alloc(sizeof(ERL_NIF_TERM) * [participants count]);
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
        
        return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
    }
}

static ErlNifFunc nif_funcs[] = {
    {"send_message", 2, send_message},
    {"send_to_chat", 2, send_to_chat},
    {"list_chats", 0, list_chats}
};

ERL_NIF_INIT(Elixir.Imessaged.Native, nif_funcs, NULL, NULL, NULL, NULL) 