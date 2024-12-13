defmodule Imessaged.Native do
  @on_load :load_nif

  def load_nif do
    path = :filename.join(:code.priv_dir(:imessaged), "imessaged_nif")
    :erlang.load_nif(String.to_charlist(path), 0)
  end

  @spec send_message_to_buddy(bitstring(), bitstring()) :: :ok | {:error, bitstring()}
  def send_message_to_buddy(_message, _handle), do: :erlang.nif_error(:nif_not_loaded)

  @spec send_message_to_chat(bitstring(), bitstring()) :: :ok | {:error, bitstring()}
  def send_message_to_chat(_message, _chat_id), do: :erlang.nif_error(:nif_not_loaded)

  @spec list_chats() ::
          {:ok, list(%{id: bitstring(), name: bitstring(), participants: list(bitstring())})}
          | {:error, bitstring()}
  def list_chats(), do: :erlang.nif_error(:nif_not_loaded)

  @spec list_buddies() ::
          {:ok, list(%{id: bitstring(), handle: bitstring()})}
          | {:error, bitstring()}
  def list_buddies(), do: :erlang.nif_error(:nif_not_loaded)

  def list_chat_properties(), do: :erlang.nif_error(:nif_not_loaded)

  def list_chat_methods(), do: :erlang.nif_error(:nif_not_loaded)
end
