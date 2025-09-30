defmodule Imessaged.Messages do
  @moduledoc """
  Functions for reading message data from the SQLite database.
  """

  alias Imessaged.DB
  alias Imessaged.TypedStream
  alias Imessaged.MessageTypes

  @message_fields """
  m.ROWID as message_id,
  m.guid,
  CASE
    WHEN m.text IS NOT NULL AND m.text != '' THEN m.text
    WHEN m.attributedBody IS NOT NULL THEN hex(m.attributedBody)
    ELSE NULL
  END as content,
  datetime(m.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as date,
  datetime(m.date_read/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as date_read,
  datetime(m.date_delivered/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as date_delivered,
  h.id as sender,
  m.is_from_me,
  m.is_read,
  m.item_type,
  m.service,
  m.cache_has_attachments,
  m.subject,
  CASE
    WHEN m.text IS NOT NULL AND m.text != '' THEN 0
    WHEN m.attributedBody IS NOT NULL THEN 1
    ELSE 2
  END as content_type,
  m.associated_message_type,
  m.associated_message_guid,
  m.associated_message_emoji,
  m.balloon_bundle_id,
  m.expressive_send_style_id,
  m.thread_originator_guid,
  m.thread_originator_part,
  m.date_edited,
  m.group_title,
  m.group_action_type,
  c.chat_id,
  (SELECT COUNT(*) FROM message_attachment_join a WHERE m.ROWID = a.message_id) as num_attachments,
  (SELECT COUNT(*) FROM message m2 WHERE m2.thread_originator_guid = m.guid) as num_replies
  """

  @doc """
  Get messages for a specific chat.
  """
  def get_messages(chat_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    query = """
    SELECT #{@message_fields}
    FROM message m
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    LEFT JOIN chat_message_join c ON m.ROWID = c.message_id
    WHERE c.chat_id = ?1
      AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL OR m.cache_has_attachments = 1)
      AND m.is_from_me IS NOT NULL
    ORDER BY m.date DESC
    LIMIT ?2
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [chat_id, limit]) do
      messages = Enum.map(rows, &parse_message_row/1)
      {:ok, messages}
    end
  end

  @doc """
  Get a specific message by ROWID.
  """
  def get_message(message_id) do
    query = """
    SELECT #{@message_fields}
    FROM message m
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    LEFT JOIN chat_message_join c ON m.ROWID = c.message_id
    WHERE m.ROWID = ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [message_id]) do
      case rows do
        [row] -> {:ok, parse_message_row(row)}
        [] -> {:error, "Message with ROWID #{message_id} not found"}
      end
    end
  end

  @doc """
  Get recent messages across all chats.
  """
  def get_recent_messages(limit \\ 10) do
    query = """
    SELECT #{@message_fields}
    FROM message m
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    LEFT JOIN chat_message_join c ON m.ROWID = c.message_id
    WHERE (m.text IS NOT NULL OR m.attributedBody IS NOT NULL OR m.cache_has_attachments = 1)
      AND m.is_from_me IS NOT NULL
    ORDER BY m.date DESC
    LIMIT ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [limit]) do
      messages = Enum.map(rows, &parse_message_row/1)
      {:ok, messages}
    end
  end

  @doc """
  Get messages since a specific ROWID (for polling new messages).
  Returns messages in ascending order by ROWID.
  """
  def get_messages_since(last_rowid, opts \\ []) do
    limit = Keyword.get(opts, :limit, 1000)

    query = """
    SELECT #{@message_fields}
    FROM message m
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    LEFT JOIN chat_message_join c ON m.ROWID = c.message_id
    WHERE m.ROWID > ?1
      AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL OR m.cache_has_attachments = 1)
      AND m.is_from_me IS NOT NULL
    ORDER BY m.ROWID ASC
    LIMIT ?2
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [last_rowid, limit]) do
      messages = Enum.map(rows, &parse_message_row/1)
      {:ok, messages}
    end
  end

  # Private helpers

  defp parse_message_row(row) do
    [
      rowid,
      guid,
      content,
      date,
      date_read,
      date_delivered,
      sender,
      from_me,
      is_read,
      item_type,
      service,
      has_attachments,
      subject,
      content_type,
      associated_message_type,
      associated_message_guid,
      associated_message_emoji,
      balloon_bundle_id,
      expressive_send_style_id,
      thread_originator_guid,
      thread_originator_part,
      date_edited,
      group_title,
      group_action_type,
      chat_id,
      num_attachments,
      num_replies
    ] = row

    parsed_content =
      if content_type == 1 && is_binary(content) do
        case Base.decode16(content, case: :mixed) do
          {:ok, binary_data} ->
            parsed = TypedStream.parse_typedstream(binary_data)
            TypedStream.extract_text(parsed)

          :error ->
            content
        end
      else
        content
      end

    %{
      "ROWID" => rowid,
      "guid" => guid,
      "content" => parsed_content,
      "date" => date,
      "date_read" => date_read,
      "date_delivered" => date_delivered,
      "sender" => sender,
      "from_me" => from_me,
      "is_read" => is_read,
      "item_type" => item_type,
      "service" => service,
      "has_attachments" => has_attachments,
      "num_attachments" => num_attachments,
      "subject" => subject,
      "content_type" => content_type,
      "is_tapback" => MessageTypes.is_tapback?(associated_message_type),
      "tapback_info" =>
        MessageTypes.decode_tapback(associated_message_type, associated_message_emoji),
      "references_message" => associated_message_guid,
      "balloon_bundle_id" => balloon_bundle_id,
      "expressive_send_style_id" => expressive_send_style_id,
      "thread_originator_guid" => thread_originator_guid,
      "thread_originator_part" => thread_originator_part,
      "num_replies" => num_replies,
      "date_edited" => date_edited,
      "is_edited" => date_edited != 0 && date_edited != nil,
      "group_title" => group_title,
      "group_action_type" => group_action_type,
      "chat_id" => chat_id
    }
  end
end
