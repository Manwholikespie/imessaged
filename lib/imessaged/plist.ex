defmodule Imessaged.Plist do
  @spec decode(binary()) :: {:ok, any()}
  def decode(data) do
    {:ok, Plist.Binary.decode(data)}
  end
end
