defmodule Imessaged.Router do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  alias Imessaged.Messages

  # V1 API - Resource-oriented design

  # Chats
  get "/v1/chats" do
    case Imessaged.list_chats() do
      {:ok, chats} -> send_json(conn, 200, %{data: chats})
      {:error, reason} -> send_json(conn, 500, %{error: reason})
    end
  end

  get "/v1/chats/:id/messages" do
    limit = conn.params["limit"] || conn.query_params["limit"] || "10"
    limit = String.to_integer(limit)

    case Messages.get_messages(id, limit: limit) do
      {:ok, messages} -> send_json(conn, 200, %{data: messages})
      {:error, reason} -> send_json(conn, 500, %{error: reason})
    end
  end

  post "/v1/chats/:id/messages" do
    case Map.fetch(conn.body_params, "message") do
      {:ok, message} when is_binary(message) ->
        case Imessaged.send_message_to_chat(message, id) do
          :ok -> send_json(conn, 200, %{status: "ok"})
          {:error, reason} -> send_json(conn, 400, %{error: reason})
        end

      _ ->
        send_json(conn, 400, %{error: "Invalid or missing message parameter"})
    end
  end

  # Buddies
  get "/v1/buddies" do
    case Imessaged.list_buddies() do
      {:ok, buddies} -> send_json(conn, 200, %{data: buddies})
      {:error, reason} -> send_json(conn, 500, %{error: reason})
    end
  end

  post "/v1/buddies/:handle/messages" do
    case Map.fetch(conn.body_params, "message") do
      {:ok, message} when is_binary(message) ->
        case Imessaged.send_message_to_buddy(message, handle) do
          :ok -> send_json(conn, 200, %{status: "ok"})
          {:error, reason} -> send_json(conn, 400, %{error: reason})
        end

      _ ->
        send_json(conn, 400, %{error: "Invalid or missing message parameter"})
    end
  end

  # Messages
  get "/v1/messages/:id" do
    message_id = String.to_integer(id)

    case Messages.get_message(message_id) do
      {:ok, message} -> send_json(conn, 200, %{data: message})
      {:error, reason} -> send_json(conn, 404, %{error: reason})
    end
  end

  # Attachments
  post "/v1/attachments" do
    with {:ok, file_path} <- Map.fetch(conn.body_params, "file_path"),
         {:ok, target} <- get_attachment_target(conn.body_params) do
      case target do
        {:buddy, handle} ->
          case Imessaged.send_file_to_buddy(file_path, handle) do
            :ok -> send_json(conn, 200, %{status: "ok"})
            {:error, reason} -> send_json(conn, 400, %{error: reason})
          end

        {:chat, chat_id} ->
          case Imessaged.send_file_to_chat(file_path, chat_id) do
            :ok -> send_json(conn, 200, %{status: "ok"})
            {:error, reason} -> send_json(conn, 400, %{error: reason})
          end
      end
    else
      :error -> send_json(conn, 400, %{error: "Missing required parameters"})
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  # Helper functions
  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defp get_attachment_target(params) do
    cond do
      Map.has_key?(params, "handle") -> {:ok, {:buddy, params["handle"]}}
      Map.has_key?(params, "chat_id") -> {:ok, {:chat, params["chat_id"]}}
      true -> :error
    end
  end
end
