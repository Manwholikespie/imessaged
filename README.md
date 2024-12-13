# imessaged

This project provides a lightweight server for programmatically interacting with Messages.app on macOS. It allows you to send iMessages and respond to received messages through either a REST API or as a dependency for your Elixir application. The functionality was originally part of my multi-platform bot Sue, but has been extracted into a standalone program for broader use.

## How does it work?

Messages.app exposes a Scripting Definition File (sdef). Using Apple's sdp tool, we can generate a header file. Our Objective-C code leverages this interface and loads into Elixir as a NIF.

## Caveats

**Important!** Messages.app has restrictions on which directories you can send files from. While the logic of allowed directories is not documented, we have confirmed that `~/Pictures` is an allowed location.

## What methods are available?

```
send_message_to_buddy(messageBody, phone_or_email)
send_message_to_chat(messageBody, internal_chat_id)
send_file_to_buddy(filePath, phone_or_email)
send_file_to_chat(filePath, internal_chat_id)
```

## TODO

- [X] Send messages to individuals and groups
- [X] Send files to individuals and groups
- [ ] Redo deleted REST API
- [ ] Figure out cleaner way to read messages. Sqlite may be only option. Unless... ;)
- [ ] Easy install
- [ ] Send fireworks, etc.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
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

