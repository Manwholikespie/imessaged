defmodule Imessaged.MessageTypes do
  @moduledoc """
  Utilities for identifying and decoding message types like tapbacks.
  """

  @doc """
  Check if a message is a tapback based on its associated_message_type.
  """
  def is_tapback?(type) when is_integer(type) do
    type in 2000..2007 or type in 3000..3007
  end

  def is_tapback?(_), do: false

  @doc """
  Decode tapback information from associated_message_type.
  """
  def decode_tapback(type, emoji \\ nil)

  def decode_tapback(2000, _), do: %{"type" => "Loved", "emoji" => "❤️", "action" => "added"}
  def decode_tapback(2001, _), do: %{"type" => "Liked", "emoji" => "👍", "action" => "added"}
  def decode_tapback(2002, _), do: %{"type" => "Disliked", "emoji" => "👎", "action" => "added"}
  def decode_tapback(2003, _), do: %{"type" => "Laughed", "emoji" => "😂", "action" => "added"}
  def decode_tapback(2004, _), do: %{"type" => "Emphasized", "emoji" => "‼️", "action" => "added"}
  def decode_tapback(2005, _), do: %{"type" => "Questioned", "emoji" => "❓", "action" => "added"}

  def decode_tapback(2006, emoji),
    do: %{"type" => "Custom", "emoji" => emoji || "?", "action" => "added"}

  def decode_tapback(2007, _), do: %{"type" => "Sticker", "action" => "added"}

  def decode_tapback(3000, _), do: %{"type" => "Loved", "emoji" => "❤️", "action" => "removed"}
  def decode_tapback(3001, _), do: %{"type" => "Liked", "emoji" => "👍", "action" => "removed"}
  def decode_tapback(3002, _), do: %{"type" => "Disliked", "emoji" => "👎", "action" => "removed"}
  def decode_tapback(3003, _), do: %{"type" => "Laughed", "emoji" => "😂", "action" => "removed"}

  def decode_tapback(3004, _),
    do: %{"type" => "Emphasized", "emoji" => "‼️", "action" => "removed"}

  def decode_tapback(3005, _),
    do: %{"type" => "Questioned", "emoji" => "❓", "action" => "removed"}

  def decode_tapback(3006, emoji),
    do: %{"type" => "Custom", "emoji" => emoji || "?", "action" => "removed"}

  def decode_tapback(3007, _), do: %{"type" => "Sticker", "action" => "removed"}

  def decode_tapback(_, _), do: nil
end
