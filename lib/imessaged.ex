defmodule Imessaged do
  alias Imessaged.Query

  @doc """
  Retrieve messages with optional filters
  """
  def get_messages(filters \\ []) do
    limit_clause = filters |> Keyword.get(:limit, "") |> format_limit_clause()

    """
    SELECT * FROM message
    WHERE 1=1
    #{filters_to_sql(filters)}
    ORDER BY date DESC
    #{limit_clause};
    """
    |> Query.query()
  end

  @doc """
  Retrieve a message by ID
  """
  def get_message(id) do
    Query.query("SELECT * FROM message WHERE ROWID = #{id};")
  end

  # Retrieve chats with optional filters
  def get_chats(filters \\ []) do
    limit_clause = filters |> Keyword.get(:limit, "") |> format_limit_clause()

    """
    SELECT * FROM chat
    WHERE 1=1
    #{filters_to_sql(filters)}
    ORDER BY last_read_message_timestamp DESC
    #{limit_clause};
    """
    |> Query.query()
  end

  # Retrieve a chat by ID
  @spec get_chat(any()) :: any()
  def get_chat(id) do
    Query.query("SELECT * FROM chat WHERE ROWID = #{id};")
  end

  # Retrieve attachments with optional filters
  def get_attachments(filters \\ []) do
    limit_clause = filters |> Keyword.get(:limit, "") |> format_limit_clause()

    """
    SELECT * FROM attachment
    WHERE 1=1
    #{filters_to_sql(filters)}
    ORDER BY created_date DESC
    #{limit_clause};
    """
    |> Query.query()
  end

  # Retrieve an attachment by ID
  def get_attachment(id) do
    Query.query("SELECT * FROM attachment WHERE ROWID = #{id};")
  end

  # Retrieve handles with optional filters
  def get_handles(filters \\ []) do
    limit_clause = filters |> Keyword.get(:limit, "") |> format_limit_clause()

    """
    SELECT * FROM handle
    WHERE 1=1
    #{filters_to_sql(filters)}
    ORDER BY id ASC
    #{limit_clause};
    """
    |> Query.query()
  end

  # Retrieve a handle by ID
  def get_handle(id) do
    Query.query("SELECT * FROM handle WHERE ROWID = #{id};")
  end

  # Retrieve attachments for a message
  def get_message_attachments(message_id) do
    """
    SELECT attachment.* FROM attachment
    JOIN message_attachment_join ON attachment.ROWID = message_attachment_join.attachment_id
    WHERE message_attachment_join.message_id = #{message_id};
    """
    |> Query.query()
  end

  # Search messages
  def search_messages(query_str, filters \\ []) do
    limit_clause = filters |> Keyword.get(:limit, "") |> format_limit_clause()

    """
    SELECT * FROM message
    WHERE text LIKE '%' || #{query_str} || '%'
    #{filters_to_sql(filters)}
    ORDER BY date DESC
    #{limit_clause};
    """
    |> Query.query()
  end

  # Retrieve recent chats
  def get_recent_chats(limit \\ 10) do
    """
    SELECT * FROM chat
    ORDER BY last_read_message_timestamp DESC
    LIMIT #{limit};
    """
    |> Query.query()
  end

  # Retrieve chat participants
  def get_chat_participants(chat_id) do
    """
    SELECT handle.* FROM handle
    JOIN chat_handle_join ON handle.ROWID = chat_handle_join.handle_id
    WHERE chat_handle_join.chat_id = #{chat_id};
    """
    |> Query.query()
  end

  # Helper function to convert filters to SQL conditions
  defp filters_to_sql(filters) do
    filters
    |> Enum.filter(fn {key, _} -> key != :limit end)
    |> Enum.map(fn
      {:sinceTimestamp, ts} -> "AND date > #{ts}"
      {:sinceRowID, row_id} -> "AND ROWID > #{row_id}"
      {:chatID, chat_id} -> "AND chat_id = #{chat_id}"
      {:senderID, sender_id} -> "AND handle_id = #{sender_id}"
      {:isFromMe, is_from_me} -> "AND is_from_me = #{is_from_me}"
      {:hasAttachments, has_attachments} -> "AND cache_has_attachments = #{has_attachments}"
      {:isRead, is_read} -> "AND is_read = #{is_read}"
      _ -> ""
    end)
    |> Enum.join(" ")
  end

  # Helper function to format the LIMIT clause
  defp format_limit_clause(limit) when limit == "", do: ""
  defp format_limit_clause(limit), do: "LIMIT #{limit}"

  def send_message(body, recipient_or_chat_id)
      when is_bitstring(body) and is_bitstring(recipient_or_chat_id) do
    Imessaged.Nif.send_message(
      String.to_charlist(body),
      String.to_charlist(recipient_or_chat_id)
    )
  end
end
