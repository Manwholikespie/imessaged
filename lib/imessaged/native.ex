defmodule Imessaged.Native do
  @on_load :load_nif
  require Logger

  def load_nif do
    path = :filename.join(:code.priv_dir(:imessaged), "imessaged_nif")
    Logger.debug("Loading NIF from path: #{path}")
    case :erlang.load_nif(String.to_charlist(path), 0) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Failed to load NIF: #{inspect(reason)}")
    end
  end

  def load_sdef(path) when is_binary(path) do
    Logger.debug("Calling load_sdef with path: #{path}")
    case File.exists?(path) do
      true ->
        do_load_sdef(path)
      false ->
        {:error, :file_not_found}
    end
  end

  defp do_load_sdef(_path) do
    raise "NIF load_sdef/1 not implemented"
  end

  def hello_nif do
    raise "NIF hello_nif/0 not implemented"
  end
end
