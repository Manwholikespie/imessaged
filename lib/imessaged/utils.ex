defmodule Imessaged.Utils do
  def is_phone_number?(str) do
    String.match?(str, ~r/^\+?\d{10,15}$/)
  end

  def is_email?(str) do
    String.match?(str, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end
end
