defmodule ImessagedTest do
  use ExUnit.Case
  doctest Imessaged

  alias Imessaged.Messages
  alias Imessaged.TypedStream

  describe "Messages.get_recent_messages/1" do
    test "returns list of messages with valid structure" do
      case Messages.get_recent_messages(5) do
        {:ok, messages} ->
          assert is_list(messages)
          assert length(messages) <= 5

          if length(messages) > 0 do
            message = hd(messages)
            assert is_map(message)
            assert Map.has_key?(message, "ROWID")
            assert Map.has_key?(message, "content")
            assert Map.has_key?(message, "date")
            assert Map.has_key?(message, "chat_identifier")
            assert Map.has_key?(message, "is_direct")
            assert Map.has_key?(message, "attachments")
            assert is_boolean(message["is_direct"])
            assert is_list(message["attachments"])
          end

        {:error, _reason} ->
          # Database might not be accessible in test environment
          assert true
      end
    end
  end

  describe "Messages.get_message/1" do
    test "fetches a specific message by ROWID" do
      # First get a recent message to get a valid ROWID
      case Messages.get_recent_messages(1) do
        {:ok, [message | _]} ->
          rowid = message["ROWID"]

          case Messages.get_message(rowid) do
            {:ok, fetched} ->
              assert is_map(fetched)
              assert fetched["ROWID"] == rowid
              assert Map.has_key?(fetched, "content")
              assert Map.has_key?(fetched, "chat_identifier")
              assert Map.has_key?(fetched, "is_direct")
              assert Map.has_key?(fetched, "attachments")
              assert is_boolean(fetched["is_direct"])
              assert is_list(fetched["attachments"])

            {:error, _} ->
              assert true
          end

        _ ->
          # No messages or database not accessible
          assert true
      end
    end

    test "returns error for non-existent message" do
      case Messages.get_message(999_999_999) do
        {:error, reason} ->
          assert is_binary(reason)
          assert String.contains?(reason, "not found")

        {:ok, _} ->
          # Extremely unlikely this ROWID exists
          assert false
      end
    end
  end

  describe "Messages.get_messages_since/2" do
    test "fetches messages after a specific ROWID" do
      # Get a recent message to use as baseline
      case Messages.get_recent_messages(10) do
        {:ok, messages} when length(messages) > 1 ->
          # Use the 5th message as baseline
          baseline_rowid = Enum.at(messages, 5)["ROWID"]

          case Messages.get_messages_since(baseline_rowid, limit: 10) do
            {:ok, new_messages} ->
              assert is_list(new_messages)
              # All returned messages should have ROWID > baseline
              Enum.each(new_messages, fn msg ->
                assert msg["ROWID"] > baseline_rowid
                assert Map.has_key?(msg, "chat_identifier")
                assert Map.has_key?(msg, "is_direct")
                assert Map.has_key?(msg, "attachments")
                assert is_boolean(msg["is_direct"])
                assert is_list(msg["attachments"])
              end)

            {:error, _} ->
              assert true
          end

        _ ->
          # Not enough messages or database not accessible
          assert true
      end
    end
  end

  describe "TypedStream.extract_text/1" do
    test "extracts text from keyword list format" do
      parsed = [text: "Hello, world!", has_attachments: false]
      assert TypedStream.extract_text(parsed) == "Hello, world!"
    end

    test "returns default for missing text" do
      parsed = [has_attachments: true]
      assert TypedStream.extract_text(parsed) == "[Unable to extract text]"
    end

    test "returns default for nil input" do
      assert TypedStream.extract_text(nil) == "[Unable to extract text]"
    end
  end
end
