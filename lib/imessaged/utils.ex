defmodule Imessaged.Utils do
  def is_phone_number?(str) do
    String.match?(str, ~r/^\+?\d{10,15}$/)
  end

  def is_email?(str) do
    String.match?(str, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  @spec hash_file(Path.t()) :: binary()
  def hash_file(path) do
    File.stream!(path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
end
