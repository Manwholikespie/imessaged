defmodule Imessaged.Models.Message do
  @moduledoc """
  Represents an iMessage message with support for edit history.
  """

  defstruct [
    :id,                # ROWID from SQLite
    :guid,             # Unique message identifier
    :text,             # Message content
    :date,             # Timestamp of message
    :date_edited,      # Timestamp of edit if edited
    :is_from_me,       # Boolean indicating if sent by user
    :edit_history,     # List of previous versions if edited
    :service          # iMessage/SMS
  ]

  @type t :: %__MODULE__{
    id: integer(),
    guid: String.t(),
    text: String.t(),
    date: integer(),
    date_edited: integer() | nil,
    is_from_me: boolean(),
    edit_history: list(map()) | nil,
    service: String.t()
  }
end
