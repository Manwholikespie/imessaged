defmodule Imessaged.DB do
  @moduledoc """
  Handles SQLite database connections for iMessage access.
  """

  alias Exqlite.Sqlite3

  @db_path "~/Library/Messages/chat.db"

  def connect do
    Sqlite3.open(Path.expand(@db_path))
  end

  def disconnect(conn) do
    Sqlite3.close(conn)
  end

  @doc """
  Executes a query with parameters and returns all rows.
  """
  def query(conn, sql, params \\ []) do
    with {:ok, statement} <- Sqlite3.prepare(conn, sql),
         :ok <- bind_params(conn, statement, params),
         {:ok, rows} <- fetch_all(conn, statement) do
      {:ok, rows}
    end
  end

  # Private helpers

  defp bind_params(_conn, statement, params) do
    Enum.reduce_while(params, :ok, fn param, :ok ->
      case Sqlite3.bind(statement, [param]) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp fetch_all(conn, statement) do
    fetch_all_rows(conn, statement, [])
  end

  defp fetch_all_rows(conn, statement, acc) do
    case Sqlite3.step(conn, statement) do
      {:row, row} -> fetch_all_rows(conn, statement, [row | acc])
      :done -> {:ok, Enum.reverse(acc)}
      error -> error
    end
  end
end
