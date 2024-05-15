defmodule Imessaged.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Imessaged.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: Imessaged.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
