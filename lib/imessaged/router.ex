defmodule Imessaged.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  @impl true
  def init(options), do: options

  get "/" do
    send_resp(conn, 200, "online")
  end

  # Retrieve messages
  get "/messages" do
    filters = Enum.map(conn.query_params, fn {k, v} -> {String.to_atom(k), v} end)

    messages =
      Imessaged.get_messages(filters)
      |> Enum.map(&encode_binary_values/1)

    send_json(conn, 200, messages)
  end

  # Retrieve message by ID
  get "/messages/:id" do
    id = String.to_integer(conn.params["id"])
    message = Imessaged.get_message(id)
    send_json(conn, 200, message)
  end

  # Retrieve chats
  get "/chats" do
    filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
    chats = Imessaged.get_chats(filters)
    send_json(conn, 200, chats)
  end

  # Retrieve chat by ID
  get "/chats/:id" do
    id = String.to_integer(conn.params["id"])
    chat = Imessaged.get_chat(id)
    send_json(conn, 200, chat)
  end

  # Retrieve attachments
  get "/attachments" do
    filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
    attachments = Imessaged.get_attachments(filters)
    send_json(conn, 200, attachments)
  end

  # Retrieve attachment by ID
  get "/attachments/:id" do
    id = String.to_integer(conn.params["id"])
    attachment = Imessaged.get_attachment(id)
    send_json(conn, 200, attachment)
  end

  # Retrieve handles
  get "/handles" do
    filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
    handles = Imessaged.get_handles(filters)
    send_json(conn, 200, handles)
  end

  # Retrieve handle by ID
  get "/handles/:id" do
    id = String.to_integer(conn.params["id"])
    handle = Imessaged.get_handle(id)
    send_json(conn, 200, handle)
  end

  # Retrieve messages in a chat
  get "/chats/:chatID/messages" do
    chat_id = String.to_integer(conn.params["chatID"])
    filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
    messages = Imessaged.get_messages(Keyword.put(filters, :chatID, chat_id))
    send_json(conn, 200, messages)
  end

  # Retrieve attachments in a chat
  # get "/chats/:chatID/attachments" do
  #   chat_id = String.to_integer(conn.params["chatID"])
  #   filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
  #   attachments = Imessaged.get_attachments(Keyword.put(filters, :chatID, chat_id))
  #   send_json(conn, 200, attachments)
  # end

  # Send a message
  post "/messages/send" do
    %{
      "recipient_id" => recipient_id,
      "text" => text
    } = conn.body_params

    :ok = Imessaged.send_message(text, recipient_id)
    send_json(conn, 201, %{status: "Message sent"})
  end

  # Send an attachment
  # post "/attachments/send" do
  #   %{"recipient_id" => recipient_id, "file" => file, "isSticker" => is_sticker} =
  #     conn.body_params

  #   is_sticker = is_sticker || false
  #   :ok = Imessaged.send_attachment(recipient_id, file, is_sticker)
  #   send_resp(conn, 201, Jason.encode!(%{status: "Attachment sent"}))
  # end

  # Retrieve message attachments
  get "/messages/:id/attachments" do
    message_id = String.to_integer(conn.params["id"])
    attachments = Imessaged.get_message_attachments(message_id)
    send_json(conn, 200, attachments)
  end

  # Search messages
  get "/messages/search" do
    query_str = conn.params["query"]
    filters = Enum.map(conn.params, fn {k, v} -> {String.to_atom(k), v} end)
    messages = Imessaged.search_messages(query_str, filters)
    send_json(conn, 200, messages)
  end

  # Retrieve recent chats
  get "/chats/recent" do
    limit = conn.params["limit"] || 10
    limit = String.to_integer(limit)
    chats = Imessaged.get_recent_chats(limit)
    send_json(conn, 200, chats)
  end

  # Retrieve chat participants
  get "/chats/:chatID/participants" do
    chat_id = String.to_integer(conn.params["chatID"])
    participants = Imessaged.get_chat_participants(chat_id)
    send_json(conn, 200, participants)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, Jason.encode!(%{error: "Something went wrong"}))
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  @spec encode_binary_values(map()) :: map()
  defp encode_binary_values(m) when is_map(m) do
    Enum.map(m, fn {k, v} ->
      if is_binary(v) and not String.valid?(v) do
        {k, :base64.encode(v)}
      else
        {k, v}
      end
    end)
    |> Map.new()
  end
end
