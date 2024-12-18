defmodule Imessaged.Debug do
  @moduledoc """
  Development-only utilities for investigating message structures.
  Not for production use.
  """

  alias Imessaged.DB

  @doc """
  Lists all edited messages within a specific time range for investigation.
  """
  @spec list_edited_messages(keyword()) ::
          {:ok, [{String.t(), integer(), map() | nil}]} | {:error, term()}
  def list_edited_messages(opts \\ []) do
    query = """
    SELECT guid, date_edited, message_summary_info
    FROM message
    WHERE date_edited > 0
    ORDER BY date_edited DESC
    LIMIT ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [Keyword.get(opts, :limit, 10)]) do
      results =
        Enum.map(rows, fn [guid, date, summary_info] ->
          %{guid: guid, date: date, data: parse_summary_info(summary_info)}
        end)

      {:ok, results}
    end
  end

  def bruh() do
    {:ok, msgs} = list_edited_messages()

    msgs
    |> hd()
    |> Map.get(:data)
    |> Map.get("ec")
    |> Map.get("0")
    |> hd()
    |> Map.get("t")
  end

  def parse_summary_info(summary_info) when is_binary(summary_info) do
    {:ok, data} = Imessaged.Plist.decode(summary_info)
    data
  end
end
