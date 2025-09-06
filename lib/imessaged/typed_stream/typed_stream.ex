defmodule Imessaged.TypedStream do
  use Rustler, otp_app: :imessaged, crate: :imessage_parser

  @doc """
  Parses a typedstream binary into a structured format.
  """
  def parse_typedstream(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Extracts text content from parsed typedstream data.
  The new NIF returns a keyword list with :text, :has_attachments, :has_mentions, :has_links
  """
  def extract_text(parsed) when is_list(parsed) do
    # Check if it's the new format (keyword list)
    if Keyword.keyword?(parsed) do
      Keyword.get(parsed, :text, "[Unable to extract text]")
    else
      # Fallback for old format (list of maps) - kept for compatibility
      Enum.find_value(parsed, fn
        %{class_name: "NSString", data: [data | _]} ->
          # Extract the actual string from the String(...) format
          case Regex.run(~r/String\("(.*)"\)/, data) do
            [_, text] -> text
            _ -> nil
          end

        %{class_name: "NSMutableString", data: [data | _]} ->
          # Also handle NSMutableString
          case Regex.run(~r/String\("(.*)"\)/, data) do
            [_, text] -> text
            _ -> nil
          end

        _ ->
          nil
      end) || "[Unable to extract text]"
    end
  end

  def extract_text(_), do: "[Unable to extract text]"
end
