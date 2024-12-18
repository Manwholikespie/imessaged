defmodule Imessaged.TypedStream do
  use Rustler, otp_app: :imessaged, crate: :imessage_parser

  @doc """
  Parses a typedstream binary into a structured format.
  """
  def parse_typedstream(_data), do: :erlang.nif_error(:nif_not_loaded)
end
