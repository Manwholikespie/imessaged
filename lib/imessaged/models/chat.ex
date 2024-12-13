defmodule Imessaged.Models.Chat do
  @moduledoc """
  Represents a chat conversation in Messages.
  A chat can be a one-on-one conversation or a group chat.
  """

  alias __MODULE__

  alias Imessaged.Models.Contact

  @type t() :: %Chat{
          id: bitstring(),
          name: bitstring(),
          participants: [Contact.t()]
        }

  defstruct [:id, :name, :participants]

  @doc """
  Creates a new chat struct with validation.
  """
  @spec new(Keyword.t()) :: t()
  def new(attrs) do
    chat = struct!(Chat, attrs)
    {:ok, chat} = validate(chat)
    chat
  end

  @doc """
  Validates a chat struct.
  """
  def validate(%Chat{} = chat) do
    cond do
      is_nil(chat.id) or String.trim(chat.id) == "" ->
        {:error, "id is required"}

      is_nil(chat.participants) or chat.participants == [] ->
        {:error, "chat must have at least one participant"}

      not Enum.all?(chat.participants, &match?(%Contact{}, &1)) ->
        {:error, "all participants must be Contact structs"}

      true ->
        {:ok, chat}
    end
  end
end
