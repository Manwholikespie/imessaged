defmodule Imessaged.Application do
  use Application

  def start(_type, _args) do
    children = build_children()

    opts = [strategy: :one_for_one, name: Imessaged.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp build_children do
    if Application.get_env(:imessaged, :enable_rest_api, true) do
      port = Application.get_env(:imessaged, :rest_api_port, 4000)
      [{Plug.Cowboy, scheme: :http, plug: Imessaged.Router, options: [port: port]}]
    else
      []
    end
  end
end
