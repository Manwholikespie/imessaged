defmodule Imessaged.Models.Message do
  @moduledoc """
  Represents an iMessage message.
  """

  defstruct [
    # ROWID from SQLite
    :id,
    # Unique message identifier
    :guid,
    # Message content
    :text,
    # Timestamp of message
    :date,
    # Timestamp of edit if edited
    :date_edited,
    # Boolean indicating if sent by user
    :is_from_me,
    # iMessage/SMS
    :service
  ]

  @type t :: %__MODULE__{
          id: integer(),
          guid: String.t(),
          text: String.t(),
          date: integer(),
          date_edited: integer() | nil,
          is_from_me: boolean(),
          service: String.t()
        }
end
