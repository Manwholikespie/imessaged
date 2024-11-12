defmodule Imessaged.Sdef do
  alias Imessaged.Native
  require Logger

  @sdef_path Path.join(:code.priv_dir(:imessaged), "Messages.sdef")

  def load do
    Logger.debug("Loading SDEF from path: #{@sdef_path}")
    Logger.debug("File exists? #{File.exists?(@sdef_path)}")

    case File.read(@sdef_path) do
      {:ok, _content} ->
        Logger.debug("File is readable")
        Native.load_sdef(@sdef_path)
      {:error, reason} ->
        Logger.error("Cannot read file: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
