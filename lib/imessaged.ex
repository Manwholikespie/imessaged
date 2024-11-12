defmodule Imessaged do
  alias Imessaged.Native

  @doc """
  Lists all available chats with their IDs, names, and participants.

  ## Examples
      iex> Imessaged.list_chats()
      {:ok, [
        %{
          id: "iMessage;-;+1234567890",
          name: "John Doe",
          participants: ["+1234567890"]
        },
        %{
          id: "iMessage;-;group123",
          name: "Family Group",
          participants: ["mom@icloud.com", "dad@icloud.com"]
        }
      ]}
  """
  def list_chats, do: Native.list_chats()

  @doc """
  Sends a message to a specific chat by its ID.

  ## Examples
      iex> Imessaged.send_to_chat("Hello everyone!", "iMessage;-;group123")
      :ok
  """
  def send_to_chat(message, chat_id) when is_binary(message) and is_binary(chat_id) do
    Native.send_to_chat(message, chat_id)
  end

  @doc """
  Sends a message to a recipient (phone number or email).
  """
  def send_message(message, recipient) when is_binary(message) and is_binary(recipient) do
    Native.send_message(message, recipient)
  end

  @doc """
  Lists all properties of the MessagesChat class.
  """
  def list_chat_properties do
    Native.list_chat_properties()
  end

  @doc """
  Lists all methods of the MessagesChat class.
  """
  def list_chat_methods do
    Native.list_chat_methods()
  end
end
