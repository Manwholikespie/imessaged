defmodule Imessaged do
  alias Imessaged.Query

  def chats(), do: Query.chats()

  def handles(), do: Query.handles()

  def messages(), do: Query.messages()

  def send_message(body, recipient_or_chat_id)
      when is_bitstring(body) and is_bitstring(recipient_or_chat_id) do
    Imessaged.Nif.send_message(
      String.to_charlist(body),
      String.to_charlist(recipient_or_chat_id)
    )
  end
end
