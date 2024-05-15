defmodule Imessaged.Query do
  @moduledoc """
  Reads the iMessage `chat.db` Sqlite database.
  """

  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([chat_db_path]) do
    {:ok, _conn} = Exqlite.Sqlite3.open(chat_db_path)
  end

  @impl true
  def handle_call({:query, sql}, _from, conn) do
    # Prepare the SQL statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, sql)

    # Fetch the column names
    {:ok, column_names} = Exqlite.Sqlite3.columns(conn, statement)

    # Fetch all rows
    {:ok, rows} = Exqlite.Sqlite3.fetch_all(conn, statement)

    # Release the statement
    Exqlite.Sqlite3.release(conn, statement)

    # Combine column names with each row
    result_with_columns =
      Enum.map(rows, fn row ->
        Enum.zip(column_names, row)
        |> Enum.into(%{})
      end)

    {:reply, result_with_columns, conn}
  end

  def handle_call(:conn, _from, conn) do
    {:reply, conn, conn}
  end

  def conn() do
    GenServer.call(__MODULE__, :conn)
  end

  def query(q) do
    GenServer.call(__MODULE__, {:query, q})
  end
end
