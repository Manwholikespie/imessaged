defmodule Imessaged do
  alias Imessaged.Native

  @doc """
  Sends a message to an individual person by their phone number or email.
  They need to have an existing conversation with you.
  """
  def send_message_to_buddy(message, handle) when is_binary(message) and is_binary(handle) do
    Native.send_message_to_buddy(message, handle)
  end

  @doc """
  Sends a message to a specific chat by its ID.

  ## Examples
      iex> Imessaged.send_to_chat("Hello everyone!", "iMessage;-;group123")
      :ok
  """
  def send_message_to_chat(message, chat_id) when is_binary(message) and is_binary(chat_id) do
    Native.send_message_to_chat(message, chat_id)
  end

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
  List all participants across chats, providing their IDs and handles.

  ## Examples
  iex> Imessaged.list_buddies()
  {:ok,
  [
   %{
     handle: "user1@icloud.com",
     id: "A1111111-2222-3333-4444-B55566667777:user1@icloud.com"
   },
   %{
     handle: "+1234567890",
     id: "B1111111-2222-3333-4444-B55566667777:+1234567890"
   }
   %{...},
   ...
   ]}
  """
  def list_buddies, do: Native.list_buddies()

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
