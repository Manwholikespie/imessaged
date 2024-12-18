defmodule Imessaged.Messages do
  @moduledoc """
  Service for retrieving messages with support for filtering and edit history.
  """

  alias Imessaged.Models.Message
  alias Imessaged.DB

  @max_page_size 1000
  @default_page_size 100

  @doc """
  Lists messages since a given timestamp or row ID.

  ## Options
    * `:since_time` - Get messages after this timestamp
    * `:since_id` - Get messages after this row ID
    * `:page_size` - Maximum number of messages to return (default: 100, max: 1000)
    * `:service` - Filter by service type ("iMessage" or "SMS")

  ## Examples
      iex> list_messages(since_time: 1234567890)
      {:ok, [%Message{...}]}

      iex> list_messages(since_id: 12345, service: "iMessage")
      {:ok, [%Message{...}]}
  """
  @spec list_messages(keyword()) :: {:ok, [Message.t()]} | {:error, term()}
  def list_messages(opts \\ []) do
    page_size = validate_page_size(opts)

    query = """
    SELECT
      m.ROWID,
      m.guid,
      m.text,
      m.date,
      m.date_edited,
      m.is_from_me,
      m.service,
      m.message_summary_info
    FROM message m
    WHERE 1=1
    #{build_where_clauses(opts)}
    ORDER BY m.date DESC
    LIMIT ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, build_params(opts, page_size)) do
      messages = Enum.map(rows, &row_to_message/1)
      {:ok, messages}
    end
  end

  @doc """
  Gets a single message by its GUID.

  Returns `{:error, :not_found}` if the message doesn't exist.
  """
  @spec get_message(String.t()) :: {:ok, Message.t()} | {:error, :not_found} | {:error, term()}
  def get_message(guid) when is_binary(guid) do
    query = """
    SELECT
      m.ROWID,
      m.guid,
      m.text,
      m.date,
      m.date_edited,
      m.is_from_me,
      m.service,
      m.message_summary_info
    FROM message m
    WHERE m.guid = ?1
    LIMIT 1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [guid]) do
      case rows do
        [row] -> {:ok, row_to_message(row)}
        [] -> {:error, :not_found}
      end
    end
  end

  # Private helpers

  defp validate_page_size(opts) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    min(page_size, @max_page_size)
  end

  defp build_where_clauses(opts) do
    clauses = []

    clauses =
      if Keyword.get(opts, :since_time) do
        ["AND m.date > ?2" | clauses]
      else
        clauses
      end

    clauses =
      if Keyword.get(opts, :since_id) do
        ["AND m.ROWID > ?2" | clauses]
      else
        clauses
      end

    clauses =
      if Keyword.get(opts, :service) do
        ["AND m.service = ?3" | clauses]
      else
        clauses
      end

    Enum.join(clauses, " ")
  end

  defp build_params(opts, page_size) do
    params = [page_size]

    params =
      if time = Keyword.get(opts, :since_time) do
        [time | params]
      else
        if id = Keyword.get(opts, :since_id) do
          [id | params]
        else
          params
        end
      end

    params =
      if service = Keyword.get(opts, :service) do
        [service | params]
      else
        params
      end

    Enum.reverse(params)
  end

  defp row_to_message([rowid, guid, text, date, date_edited, is_from_me, service, summary_info]) do
    %Message{
      id: rowid,
      guid: guid,
      text: text,
      date: date,
      date_edited: date_edited,
      is_from_me: is_from_me == 1,
      service: service,
      edit_history: decode_edit_history(summary_info)
    }
  end

  defp decode_edit_history(nil), do: nil
  defp decode_edit_history(summary_info) when is_binary(summary_info) do
    # We'll implement this later when we add plist decoding
    nil
  end
end
