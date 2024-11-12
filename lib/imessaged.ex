defmodule Imessaged do
  alias Imessaged.Native

  @doc """
  Sends a message to a phone number.

  ## Examples
      iex> Imessaged.send_message("Hello!", "+1234567890")
      :ok
  """
  def send_message(message, phone_number) when is_binary(message) and is_binary(phone_number) do
    Native.send_message(message, phone_number)
  end
end
