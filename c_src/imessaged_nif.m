#include "erl_nif.h"
#import <Foundation/Foundation.h>
#import <ScriptingBridge/ScriptingBridge.h>

// Define the Messages application interface
@interface MessagesApplication : SBApplication
- (id)send:(id)text to:(id)participant;
@property (readonly) NSArray *participants;
@property (readonly) NSArray *accounts;
@end

// Forward declarations for Messages.app scripting interface
@protocol MessagesApplication
- (id)send:(id)text to:(id)participant;
@property (readonly) NSArray *participants;
@property (readonly) NSArray *accounts;
@end

@protocol MessagesParticipant
@property (readonly) NSString *handle;
@property (readonly) NSString *id;
@property (readonly) NSString *name;
@end

@protocol MessagesAccount
@property (readonly) NSString *id;
@property (readonly) NSString *serviceType; // "iMessage" or "SMS"
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

static ErlNifFunc nif_funcs[] = {
    {"send_message", 2, send_message}
};

ERL_NIF_INIT(Elixir.Imessaged.Native, nif_funcs, NULL, NULL, NULL, NULL) 