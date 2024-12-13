defmodule Imessaged.Backend.Behaviour do
  @moduledoc """
  Defines the contract for implementing a Messages backend.
  """

  alias Imessaged.Models.{Chat, Contact}

  @type error :: {:error, String.t()}

  @callback send_message_to_buddy(message :: String.t(), handle :: String.t()) ::
              :ok | error

  @callback send_message_to_chat(message :: String.t(), chat_id :: String.t()) ::
              :ok | error

  @callback list_chats() ::
              {:ok, [Chat.t()]} | error

  @callback list_buddies() ::
              {:ok, [Contact.t()]} | error
end
