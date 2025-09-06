defmodule Imessaged.Messages do
  @moduledoc """
  Service for retrieving messages with support for filtering and edit history.
  """

  alias Imessaged.DB
  alias Imessaged.TypedStream
  alias Imessaged.MessageTypes

  @doc """
  Inspect a specific message by ROWID, showing both raw and parsed attributedBody data.
  """
  def inspect_message(rowid) do
    query = """
    SELECT
        m.ROWID as message_id,
        m.text,
        m.attributedBody,
        hex(m.attributedBody) as hex_body,
        datetime(m.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as date,
        h.id as sender,
        m.is_from_me,
        m.subject,
        m.cache_has_attachments,
        m.associated_message_guid,
        m.associated_message_type,
        m.associated_message_emoji
      FROM message m
      LEFT JOIN handle h ON h.ROWID = m.handle_id
      WHERE m.ROWID = ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [rowid]) do
      case rows do
        [
          [
            _id,
            text,
            attributed_body,
            hex_body,
            date,
            sender,
            from_me,
            subject,
            has_attachments,
            associated_message_guid,
            associated_message_type,
            associated_message_emoji
          ]
        ] ->
          result = %{
            "ROWID" => rowid,
            "text" => text,
            "date" => date,
            "sender" => sender,
            "from_me" => from_me,
            "subject" => subject,
            "has_attachments" => has_attachments,
            "associated_message_guid" => associated_message_guid,
            "associated_message_type" => associated_message_type,
            "is_tapback" => MessageTypes.is_tapback?(associated_message_type),
            "tapback_info" =>
              MessageTypes.decode_tapback(associated_message_type, associated_message_emoji)
          }

          # If there's an attributedBody, parse it and show both raw and parsed
          result =
            if attributed_body != nil do
              parsed =
                case Base.decode16(hex_body, case: :mixed) do
                  {:ok, binary_data} ->
                    TypedStream.parse_typedstream(binary_data)

                  :error ->
                    "Failed to decode hex"
                end

              extracted_text = TypedStream.extract_text(parsed)

              result
              |> Map.put("hex_body", hex_body)
              |> Map.put("parsed_typedstream", parsed)
              |> Map.put("extracted_text", extracted_text)
            else
              result
            end

          {:ok, result}

        [] ->
          {:error, "Message with ROWID #{rowid} not found"}
      end
    end
  end

  @doc """
  Get recent messages with comprehensive data including replies, edits, and chat context.
  Returns the most recent messages with parsed content and full metadata.
  """
  def get_recent_messages(limit \\ 10) do
    query = """
    SELECT
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
      FROM message m
      LEFT JOIN handle h ON h.ROWID = m.handle_id
      LEFT JOIN chat_message_join c ON m.ROWID = c.message_id
      WHERE 1=1
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL OR m.cache_has_attachments = 1)
        AND m.is_from_me IS NOT NULL  -- Ensure it's a real message
      ORDER BY m.date DESC
      LIMIT ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [limit]) do
      messages =
        Enum.map(rows, fn row ->
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

          # Parse attributedBody with TypedStream if it's hex-encoded
          parsed_content =
            if content_type == 1 && is_binary(content) do
              # Content is hex-encoded attributedBody
              case Base.decode16(content, case: :mixed) do
                {:ok, binary_data} ->
                  # TypedStream.parse_typedstream returns the list directly, not {:ok, list}
                  # TypedStream.parse_typedstream returns a keyword list with :text, etc.
                  parsed = TypedStream.parse_typedstream(binary_data)
                  TypedStream.extract_text(parsed)

                # Fall back if hex decode fails
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
            # Tapback/reaction info
            "is_tapback" => MessageTypes.is_tapback?(associated_message_type),
            "tapback_info" =>
              MessageTypes.decode_tapback(associated_message_type, associated_message_emoji),
            "references_message" => associated_message_guid,
            # App messages (games, payments, etc)
            "balloon_bundle_id" => balloon_bundle_id,
            # Message effects (slam, gentle, invisible ink, etc)
            "expressive_send_style_id" => expressive_send_style_id,
            # Reply threading
            "thread_originator_guid" => thread_originator_guid,
            "thread_originator_part" => thread_originator_part,
            "num_replies" => num_replies,
            # Editing
            "date_edited" => date_edited,
            "is_edited" => date_edited != 0 && date_edited != nil,
            # Group chat info
            "group_title" => group_title,
            "group_action_type" => group_action_type,
            "chat_id" => chat_id
          }
        end)

      {:ok, messages}
    end
  end
end
