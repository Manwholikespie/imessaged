defmodule Imessaged.Application do
  use Application
  require Logger

  @port Application.compile_env(:imessaged, :port)
  @chat_db_path Application.compile_env(:imessaged, :chat_db_path)

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Imessaged.Router, port: @port},
      {Imessaged.Query, [@chat_db_path]}
    ]

    opts = [strategy: :one_for_one, name: Imessaged.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
