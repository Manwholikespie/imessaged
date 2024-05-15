defmodule Imessaged.Nif do
  @on_load :load_nif

  def load_nif do
    :ok = :erlang.load_nif(Path.join(:code.priv_dir(:imessaged), "my_nif"), 0)
  end

  def send_message(_text, _recipient), do: :erlang.nif_error(:nif_not_loaded)

  def get_num_participants(_guid), do: :erlang.nif_error(:nif_not_loaded)
end
