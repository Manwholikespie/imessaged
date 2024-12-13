defmodule Imessaged.Router do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # Send message to a buddy (phone/email)
  post "/api/message/buddy" do
    with {:ok, %{"message" => message, "handle" => handle}} <-
           validate_message_params(conn.body_params),
         :ok <- Imessaged.send_message_to_buddy(message, handle) do
      send_json(conn, 200, %{status: "ok"})
    else
      {:error, reason} -> send_json(conn, 400, %{error: reason})
    end
  end

  # Send message to a chat
  post "/api/message/chat" do
    with {:ok, %{"message" => message, "chat_id" => chat_id}} <-
           validate_message_params(conn.body_params),
         :ok <- Imessaged.send_message_to_chat(message, chat_id) do
      send_json(conn, 200, %{status: "ok"})
    else
      {:error, reason} -> send_json(conn, 400, %{error: reason})
    end
  end

  # List all chats
  get "/api/chats" do
    case Imessaged.list_chats() do
      {:ok, chats} -> send_json(conn, 200, %{chats: chats})
      {:error, reason} -> send_json(conn, 500, %{error: reason})
    end
  end

  # List all buddies
  get "/api/buddies" do
    case Imessaged.list_buddies() do
      {:ok, buddies} -> send_json(conn, 200, %{buddies: buddies})
      {:error, reason} -> send_json(conn, 500, %{error: reason})
    end
  end

  # Send file to buddy
  post "/api/file/buddy" do
    with {:ok, %{"file_path" => file_path, "handle" => handle}} <-
           validate_file_params(conn.body_params),
         :ok <- Imessaged.send_file_to_buddy(file_path, handle) do
      send_json(conn, 200, %{status: "ok"})
    else
      {:error, reason} -> send_json(conn, 400, %{error: reason})
    end
  end

  # Send file to chat
  post "/api/file/chat" do
    with {:ok, %{"file_path" => file_path, "chat_id" => chat_id}} <-
           validate_file_params(conn.body_params),
         :ok <- Imessaged.send_file_to_chat(file_path, chat_id) do
      send_json(conn, 200, %{status: "ok"})
    else
      {:error, reason} -> send_json(conn, 400, %{error: reason})
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

  defp validate_message_params(%{"message" => message} = params) when is_binary(message) do
    cond do
      Map.has_key?(params, "handle") ->
        {:ok, %{"message" => message, "handle" => params["handle"]}}

      Map.has_key?(params, "chat_id") ->
        {:ok, %{"message" => message, "chat_id" => params["chat_id"]}}

      true ->
        {:error, "Missing handle or chat_id parameter"}
    end
  end

  defp validate_message_params(_), do: {:error, "Invalid or missing message parameter"}

  defp validate_file_params(%{"file_path" => path} = params) when is_binary(path) do
    cond do
      Map.has_key?(params, "handle") ->
        {:ok, %{"file_path" => path, "handle" => params["handle"]}}

      Map.has_key?(params, "chat_id") ->
        {:ok, %{"file_path" => path, "chat_id" => params["chat_id"]}}

      true ->
        {:error, "Missing handle or chat_id parameter"}
    end
  end

  defp validate_file_params(_), do: {:error, "Invalid or missing file_path parameter"}
end
