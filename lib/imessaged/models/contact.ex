defmodule Imessaged.Models.Contact do
  @moduledoc """
  Represents a contact (buddy) in the Messages system.
  This could be someone with an email address or phone number.
  """

  alias __MODULE__

  defstruct [:handle]

  @type t() :: %Contact{
          handle: bitstring()
        }

  @doc """
  Creates a new contact struct with validation.
  """
  @spec new(Keyword.t()) :: t()
  def new(attrs) do
    contact = struct!(Contact, attrs)
    {:ok, contact} = validate(contact)
    contact
  end

  @doc """
  Validates a contact struct.
  """
  def validate(%Contact{} = contact) do
    cond do
      is_nil(contact.handle) or String.trim(contact.handle) == "" ->
        {:error, "handle is required"}

      # not (is_phone_number?(contact.handle) or is_email?(contact.handle)) ->
      #   {:error, "handle must be a valid phone number or email"}

      true ->
        {:ok, contact}
    end
  end
end
