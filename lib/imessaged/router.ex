defmodule Imessaged.Router do
  use Plug.Router
  require Logger

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  def init(options), do: options

  get "/" do
    send_resp(conn, 200, "online")
  end

  get "/messages" do
    mock_messages = [
      %{
        "id" => 1,
        "timestamp" => "2024-05-01T12:00:00Z",
        "sender" => "Alice",
        "content" => "Hello!"
      },
      %{"id" => 2, "timestamp" => "2024-05-02T12:00:00Z", "sender" => "Bob", "content" => "Hi!"}
    ]

    send_json(conn, 200, mock_messages)
  end

  get "/messages/sinceTimestamp" do
    mock_messages = [
      %{
        "id" => 3,
        "timestamp" => "2024-05-03T12:00:00Z",
        "sender" => "Charlie",
        "content" => "Good morning!"
      }
    ]

    send_json(conn, 200, mock_messages)
  end

  get "/messages/sinceRowID" do
    mock_messages = [
      %{
        "id" => 4,
        "timestamp" => "2024-05-04T12:00:00Z",
        "sender" => "Dave",
        "content" => "How are you?"
      }
    ]

    send_json(conn, 200, mock_messages)
  end

  get "/messages/groupChat/:id" do
    group_id = conn.params["id"]

    mock_messages = [
      %{
        "id" => 5,
        "timestamp" => "2024-05-05T12:00:00Z",
        "group_chat_id" => group_id,
        "sender" => "Eve",
        "content" => "Group chat message!"
      }
    ]

    send_json(conn, 200, mock_messages)
  end

  get "/messages/sender/:id" do
    sender_id = conn.params["id"]

    mock_messages = [
      %{
        "id" => 6,
        "timestamp" => "2024-05-06T12:00:00Z",
        "sender_id" => sender_id,
        "content" => "Sender specific message!"
      }
    ]

    send_json(conn, 200, mock_messages)
  end

  post "/sendMessage" do
    # Extract message data from the request
    message_data = conn.body_params["message"]
    Logger.info("Sending message: #{inspect(message_data)}")
    send_resp(conn, 200, "Message sent successfully!")
  end

  post "/sendAttachment" do
    # Extract attachment data from the request
    attachment_data = conn.body_params["attachment"]
    Logger.info("Sending attachment: #{inspect(attachment_data)}")
    send_resp(conn, 200, "Attachment sent successfully!")
  end

  post "/sendSticker" do
    # Extract sticker data from the request
    sticker_data = conn.body_params["sticker"]
    Logger.info("Sending sticker: #{inspect(sticker_data)}")
    send_resp(conn, 200, "Sticker sent successfully!")
  end

  post "/configureWebhook" do
    # Extract webhook configuration data from the request
    webhook_data = conn.body_params["webhook"]
    Logger.info("Configuring webhook: #{inspect(webhook_data)}")
    send_resp(conn, 200, "Webhook configured successfully!")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
