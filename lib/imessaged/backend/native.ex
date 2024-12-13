defmodule Imessaged.Backend.Native do
  @moduledoc """
  Native implementation of the Messages backend using Apple's Messages.app
  """

  @behaviour Imessaged.Backend.Behaviour

  alias Imessaged.Models.{Chat, Contact}
  alias Imessaged.Native

  @impl true
  def send_message_to_buddy(message, handle) do
    Native.send_message_to_buddy(message, handle)
  end

  @impl true
  def send_message_to_chat(message, chat_id) do
    Native.send_message_to_chat(message, chat_id)
  end

  @impl true
  def list_chats do
    case Native.list_chats() do
      {:ok, chats} ->
        {:ok, Enum.map(chats, &to_chat_struct/1)}

      {:error, _} = error ->
        error
    end
  end

  @impl true
  def list_buddies do
    case Native.list_buddies() do
      {:ok, buddies} ->
        {:ok, Enum.map(buddies, &to_contact_struct/1)}

      {:error, _} = error ->
        error
    end
  end

  # Private helpers

  defp to_chat_struct(chat) do
    Chat.new(
      id: chat.id,
      name: chat.name,
      participants: Enum.map(chat.participants, &Contact.new(handle: &1))
    )
  end

  defp to_contact_struct(buddy) do
    %Contact{
      handle: buddy.handle
    }
  end
end
