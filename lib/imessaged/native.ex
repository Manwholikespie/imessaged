defmodule Imessaged.Native do
  @on_load :load_nif

  def load_nif do
    path = :filename.join(:code.priv_dir(:imessaged), "imessaged_nif")
    :erlang.load_nif(String.to_charlist(path), 0)
  end

  def send_message(_message, _recipient), do: :erlang.nif_error(:nif_not_loaded)
  def send_to_chat(_message, _chat_id), do: :erlang.nif_error(:nif_not_loaded)
  def list_chats(), do: :erlang.nif_error(:nif_not_loaded)
  def list_chat_properties(), do: :erlang.nif_error(:nif_not_loaded)
  def list_chat_methods(), do: :erlang.nif_error(:nif_not_loaded)
end
