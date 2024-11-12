defmodule Imessaged.Native do
  @on_load :load_nif

  def load_nif do
    path = :filename.join(:code.priv_dir(:imessaged), 'imessaged_nif')
    :erlang.load_nif(path, 0)
  end

  def hello_nif do
    raise "NIF hello_nif/0 not implemented"
  end
end
