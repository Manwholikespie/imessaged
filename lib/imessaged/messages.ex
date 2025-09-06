defmodule Imessaged.Messages do
  @moduledoc """
  Service for retrieving messages with support for filtering and edit history.
  """

  alias Imessaged.Models.Message
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

              extracted_text =
                if is_list(parsed) do
                  TypedStream.extract_text(parsed)
                else
                  nil
                end

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
  Get recent messages with their content decoded from attributedBody when present.
  Returns the 10 most recent messages with parsed content.
  """
  def get_recent_messages(limit \\ 10) do
    query = """
    SELECT
        m.ROWID as message_id,
        CASE
          WHEN m.text IS NOT NULL AND m.text != '' THEN m.text
          WHEN m.attributedBody IS NOT NULL THEN hex(m.attributedBody)
          ELSE NULL
        END as content,
        datetime(m.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as date,
        h.id as sender,
        m.is_from_me,
        m.is_audio_message,
        m.cache_has_attachments,
        m.subject,
        CASE
          WHEN m.text IS NOT NULL AND m.text != '' THEN 0
          WHEN m.attributedBody IS NOT NULL THEN 1
          ELSE 2
        END as content_type,
        m.associated_message_type,
        m.associated_message_guid
      FROM message m
      INNER JOIN handle h ON h.ROWID = m.handle_id
      WHERE 1=1
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL OR m.cache_has_attachments = 1)
        AND m.is_from_me IS NOT NULL  -- Ensure it's a real message
        AND m.item_type = 0  -- Regular messages only
        AND m.is_audio_message = 0  -- Skip audio messages
      ORDER BY m.date DESC
      LIMIT ?1
    """

    with {:ok, conn} <- DB.connect(),
         {:ok, rows} <- DB.query(conn, query, [limit]) do
      messages =
        Enum.map(rows, fn row ->
          [
            rowid,
            content,
            date,
            sender,
            from_me,
            is_audio_message,
            has_attachments,
            subject,
            content_type,
            associated_message_type,
            associated_message_guid
          ] = row

          # Parse attributedBody with TypedStream if it's hex-encoded
          parsed_content =
            if content_type == 1 && is_binary(content) do
              # Content is hex-encoded attributedBody
              case Base.decode16(content, case: :mixed) do
                {:ok, binary_data} ->
                  # TypedStream.parse_typedstream returns the list directly, not {:ok, list}
                  parsed = TypedStream.parse_typedstream(binary_data)

                  if is_list(parsed) do
                    TypedStream.extract_text(parsed)
                  else
                    # Fall back to hex string if parsing fails
                    content
                  end

                # Fall back if hex decode fails
                :error ->
                  content
              end
            else
              content
            end

          %{
            "ROWID" => rowid,
            "content" => parsed_content,
            "date" => date,
            "sender" => sender,
            "from_me" => from_me,
            "is_audio_message" => is_audio_message,
            "has_attachments" => has_attachments,
            "subject" => subject,
            "content_type" => content_type,
            "is_tapback" => MessageTypes.is_tapback?(associated_message_type),
            "tapback_info" => MessageTypes.decode_tapback(associated_message_type),
            "references_message" => associated_message_guid
          }
        end)

      {:ok, messages}
    end
  end
end
