defmodule Imessaged.Backend.Mock do
  @moduledoc """
  Mock implementation of the Messages backend for testing.
  """

  @behaviour Imessaged.Backend.Behaviour

  alias Imessaged.Models.{Chat, Contact}

  @impl true
  def send_message_to_buddy(_message, handle) do
    case handle do
      "invalid" -> {:error, "Contact not found"}
      _ -> :ok
    end
  end

  @impl true
  def send_message_to_chat(_message, chat_id) do
    case chat_id do
      "invalid" -> {:error, "Chat not found"}
      _ -> :ok
    end
  end

  @impl true
  def list_chats do
    {:ok,
     [
       %Chat{
         id: "chat1",
         name: "Test Group",
         participants: [
           %Contact{handle: "+1234567890"},
           %Contact{handle: "test@example.com"}
         ]
       },
       %Chat{
         id: "chat2",
         name: "One on One",
         participants: [
           %Contact{handle: "+1987654321"}
         ]
       }
     ]}
  end

  @impl true
  def list_buddies do
    {:ok,
     [
       %Contact{handle: "+1234567890"},
       %Contact{handle: "test@example.com"},
       %Contact{handle: "+1987654321"}
     ]}
  end
end
