defmodule Imessaged do
  @moduledoc """
  High-level API for interacting with Apple Messages (iMessage).
  """

  alias Imessaged.Models.{Chat, Contact}
  import Imessaged.Utils

  @backend Application.compile_env(:imessaged, :backend, Imessaged.Backend.Native)

  @doc """
  Sends a message to an individual person by their phone number or email.
  They need to have an existing conversation with you.
  """
  @spec send_message_to_buddy(bitstring(), bitstring()) :: :ok | {:error, bitstring()}
  def send_message_to_buddy(message, handle) when is_binary(message) and is_binary(handle) do
    if is_email?(handle) or is_phone_number?(handle) do
      @backend.send_message_to_buddy(message, handle)
    else
      {:error, "Not a valid email or phone number."}
    end
  end

  @doc """
  Sends a message to a specific chat by its ID.
  """
  @spec send_message_to_chat(bitstring(), bitstring()) :: :ok | {:error, bitstring()}
  def send_message_to_chat(message, chat_id) when is_binary(message) and is_binary(chat_id) do
    @backend.send_message_to_chat(message, chat_id)
  end

  @doc """
  Lists all available chats with their IDs, names, and participants.
  """
  @spec list_chats() :: {:ok, [Chat.t()]} | {:error, bitstring()}
  def list_chats do
    @backend.list_chats()
  end

  @doc """
  Lists all participants across chats, providing their IDs and handles.
  """
  @spec list_buddies() :: {:ok, [Contact.t()]} | {:error, bitstring()}
  def list_buddies do
    @backend.list_buddies()
  end
end
