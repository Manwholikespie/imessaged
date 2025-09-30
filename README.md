# imessaged

This project provides a lightweight server for programmatically interacting with Messages.app on macOS. It allows you to send iMessages, read message history, and respond to received messages through either a REST API or as a dependency for your Elixir application. The functionality was originally part of my multi-platform bot [Sue](https://github.com/Manwholikespie/Sue), but has been extracted into a standalone program for broader use.

## How does it work?

- **Sending messages**: Uses Messages.app ScriptingBridge via Objective-C NIF
- **Reading messages**: Queries the SQLite database (`~/Library/Messages/chat.db`) with typedstream parsing for rich content

## REST API

**Get Messages from Chat**
```bash
curl "http://localhost:4000/v1/chats/iMessage;-;chat123/messages?limit=20"
```

**Get New Messages (Polling)**
```bash
# Get all messages since ROWID 12345
curl "http://localhost:4000/v1/messages?since_id=12345&limit=100"
```

**Get Specific Message**
```bash
curl http://localhost:4000/v1/messages/12345
```

**Send Message to Chat**
```bash
curl -X POST http://localhost:4000/v1/chats/iMessage;-;chat123/messages \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello group!"}'
```

**Send Message to Buddy**
```bash
curl -X POST http://localhost:4000/v1/buddies/+1234567890/messages \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'
```

**List All Chats**
```bash
curl http://localhost:4000/v1/chats
```

**List All Buddies**
```bash
curl http://localhost:4000/v1/buddies
```

**Send Attachment**
```bash
curl -X POST http://localhost:4000/v1/attachments \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "/Users/myself/Pictures/image.jpg",
    "chat_id": "iMessage;-;chat123"
  }'
```

## Elixir API

**Writing (Sending)**
```elixir
Imessaged.send_message_to_buddy(message, phone_or_email)
Imessaged.send_message_to_chat(message, chat_id)
Imessaged.send_file_to_buddy(file_path, phone_or_email)
Imessaged.send_file_to_chat(file_path, chat_id)
Imessaged.list_chats()
Imessaged.list_buddies()
```

**Reading**
```elixir
Imessaged.Messages.get_messages(chat_id, limit: 20)
Imessaged.Messages.get_message(message_id)
Imessaged.Messages.get_recent_messages(limit)
Imessaged.Messages.get_messages_since(last_rowid, limit: 100)  # For polling
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
- [X] REST API for sending and reading
- [X] Read messages from SQLite database
- [ ] Easy install
- [ ] Better logs
- [ ] Rate limiting
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
