defmodule Imessaged.TypedStream do
  use Rustler, otp_app: :imessaged, crate: :imessage_parser

  @doc """
  Parses a typedstream binary into a structured format.
  """
  def parse_typedstream(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Extracts text content from parsed typedstream data.
  Looks for NSString objects and returns the string content.
  """
  def extract_text(parsed) when is_list(parsed) do
    # Look for NSString objects in the parsed typedstream data
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

  def extract_text(_), do: "[Unable to extract text]"
end
