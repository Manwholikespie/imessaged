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

  ### PUBLIC METHODS
  def messages() do
    # rowid = get_current_max_rowid() - 10

    q = """
    SELECT * FROM message
    ORDER BY ROWID DESC
    LIMIT 10;
    """

    query(q)
  end

  def chats(), do: query("SELECT ROWID, guid, display_name FROM chat;")

  def handles(), do: query("SELECT * FROM handle;")

  def query_messages_since(rowid) do
    sql = """
    SELECT handle.id, handle.person_centric_id, message.cache_has_attachments, message.text, message.ROWID, message.cache_roomnames, message.is_from_me, message.date/1000000000 + 978307200 AS utc_date FROM message INNER JOIN handle ON message.handle_id = handle.ROWID WHERE message.ROWID > #{rowid};
    """

    query(sql)
  end

  def query_attachments_since(rowid) do
    sql = """
    SELECT attachment.ROWID AS a_id, message_attachment_join.message_id AS m_id, attachment.filename, attachment.mime_type, attachment.total_bytes FROM attachment INNER JOIN message_attachment_join ON attachment.ROWID == message_attachment_join.attachment_id WHERE message_attachment_join.message_id >= #{rowid};
    """

    query(sql)
  end

  ### PRIVATE METHODS

  def query(q) do
    GenServer.call(__MODULE__, {:query, q})
  end

  defp get_current_max_rowid() do
    query("SELECT MAX(message.ROWID) AS ROWID FROM message;")
  end
end
