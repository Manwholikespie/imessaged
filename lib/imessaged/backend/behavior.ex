defmodule Imessaged.Backend.Behaviour do
  @moduledoc """
  Defines the contract for implementing a Messages backend.
  """

  alias Imessaged.Models.{Chat, Contact}

  @type error :: {:error, bitstring()}

  @callback send_message_to_buddy(message :: bitstring(), handle :: bitstring()) ::
              :ok | error

  @callback send_message_to_chat(message :: bitstring(), chat_id :: bitstring()) ::
              :ok | error

  @callback list_chats() ::
              {:ok, [Chat.t()]} | error

  @callback list_buddies() ::
              {:ok, [Contact.t()]} | error
end
