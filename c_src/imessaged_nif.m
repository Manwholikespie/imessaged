#include "erl_nif.h"
#import <Foundation/Foundation.h>

// Helper function to convert NSString to ERL_NIF_TERM
static ERL_NIF_TERM make_string(ErlNifEnv* env, NSString* str) {
    const char* utf8Str = [str UTF8String];
    ERL_NIF_TERM binary;
    unsigned char* buff = enif_make_new_binary(env, strlen(utf8Str), &binary);
    memcpy(buff, utf8Str, strlen(utf8Str));
    return binary;
}

// Helper function to convert NSError to ERL_NIF_TERM tuple
static ERL_NIF_TERM make_error(ErlNifEnv* env, NSError* error) {
    ERL_NIF_TERM reason = make_string(env, [error localizedDescription]);
    return enif_make_tuple2(env, enif_make_atom(env, "error"), reason);
}

static ERL_NIF_TERM load_sdef(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary path_bin;
    
    if (!enif_inspect_binary(env, argv[0], &path_bin)) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_atom(env, "invalid_binary"));
    }

    // Create a null-terminated string
    char* filename = (char*)enif_alloc(path_bin.size + 1);
    if (!filename) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_atom(env, "out_of_memory"));
    }
    
    memcpy(filename, path_bin.data, path_bin.size);
    filename[path_bin.size] = '\0';

    @autoreleasepool {
        NSString* path = [NSString stringWithUTF8String:filename];
        enif_free(filename);
        
        if (!path) {
            return enif_make_tuple2(env,
                enif_make_atom(env, "error"),
                enif_make_atom(env, "invalid_utf8"));
        }
        
        NSError* error = nil;
        NSXMLDocument* sdef = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] 
                                                                  options:0 
                                                                    error:&error];
        
        if (error) {
            return make_error(env, error);
        }

        return enif_make_tuple2(env, 
                              enif_make_atom(env, "ok"),
                              make_string(env, [sdef XMLString]));
    }
}

static ErlNifFunc nif_funcs[] = {
    {"load_sdef", 1, load_sdef}
};

ERL_NIF_INIT(Elixir.Imessaged.Native, nif_funcs, NULL, NULL, NULL, NULL) 