# imessaged

This project provides a lightweight server for programmatically interacting with Messages.app on macOS. It allows you to send iMessages and respond to received messages through either a REST API or as a dependency for your Elixir application. The functionality was originally part of my multi-platform bot [Sue](https://github.com/Manwholikespie/Sue), but has been extracted into a standalone program for broader use.

## How does it work?

Messages.app exposes a Scripting Definition File (sdef). Using Apple's sdp tool, we can generate a header file. Our Objective-C code leverages this interface and loads into Elixir as a NIF.

## REST API

**Send Message to Buddy**
```bash
curl -X POST http://localhost:4000/api/message/buddy \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello from API!", 
    "handle": "+1234567890"
  }'
```

**Send Message to Chat**
```bash
curl -X POST http://localhost:4000/api/message/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello group!", 
    "chat_id": "iMessage;-;chat123"
  }'
```

**List All Chats**
```bash
curl http://localhost:4000/api/chats
```

**List All Buddies**
```bash
curl http://localhost:4000/api/buddies
```

**Send File to Buddy**
```bash
curl -X POST http://localhost:4000/api/file/buddy \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "~/Pictures/image.jpg", 
    "handle": "friend@example.com"
  }'
```

**Send File to Chat**
```bash
curl -X POST http://localhost:4000/api/file/chat \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "~/Pictures/image.jpg", 
    "chat_id": "iMessage;-;chat123"
  }'
```

## Elixir API

```
Imessaged.send_message_to_buddy(messageBody, phone_or_email)
Imessaged.send_message_to_chat(messageBody, internal_chat_id)
Imessaged.send_file_to_buddy(filePath, phone_or_email)
Imessaged.send_file_to_chat(filePath, internal_chat_id)
Imessaged.list_chats()
Imessaged.list_buddies()
```

## Installation

Assumes you have Elixir/Erlang [installed](https://gist.github.com/Manwholikespie/1bc76cba05f536fc5ec5f998cb56ac97).

```bash
MIX_ENV=prod mix release --overwrite
_build/prod/rel/imessaged/bin/imessaged start
```

## Configuration

The following configuration options are available:

```elixir
# config/config.exs
config :imessaged,
  enable_rest_api: true,
  rest_api_port: String.to_integer(System.get_env("PORT", "4000"))
```

## Caveats

### File Handling
Messages.app has restrictions on which directories you can send files from. While the logic of allowed directories is not documented, it is confirmed that `~/Pictures` is an allowed location.

When sending files through this API:
- Files larger than 100MB will be rejected
- Files outside of `~/Pictures` will be automatically copied to `~/Pictures/imessaged/working/`
- Until we add automatic cleanup of this folder, feel free to use `Imessaged.FileCleaner.cleanup()` from time to time.

### Directory Structure
The program creates and manages the following directory structure:
```
~/Pictures/
└── imessaged/
    ├── static/    # For permanent files
    └── working/   # For temporary files
```

## TODO

- [X] Send messages to individuals and groups
- [X] Send files to individuals and groups
- [X] Redo deleted REST API
- [ ] Figure out cleaner way to read messages. Sqlite may still be only option. Unless... ;)
- [ ] Easy install
- [ ] Better logs
- [ ] Send fireworks, etc.

<!-- If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `imessaged` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:imessaged, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/imessaged>.
 -->
