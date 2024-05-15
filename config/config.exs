import Config

config :imessaged,
  port: 4000,
  chat_db_path: Path.join(System.user_home(), "Library/Messages/chat.db")
