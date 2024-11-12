#include "erl_nif.h"
#import <Foundation/Foundation.h>

static ERL_NIF_TERM hello(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    return enif_make_string(env, "Hello from Objective-C!", ERL_NIF_LATIN1);
}

static ErlNifFunc nif_funcs[] = {
    {"hello_nif", 0, hello}
};

ERL_NIF_INIT(Elixir.Imessaged.Native, nif_funcs, NULL, NULL, NULL, NULL) 