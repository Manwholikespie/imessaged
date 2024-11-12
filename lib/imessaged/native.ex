defmodule Imessaged.Native do
  @on_load :load_nif

  def load_nif do
    path = :filename.join(:code.priv_dir(:imessaged), "imessaged_nif")
    :erlang.load_nif(String.to_charlist(path), 0)
  end

  def send_message(_message, _phone_number) do
    raise "NIF send_message/2 not implemented"
  end
end
