defmodule Imessaged.Models.Chat do
  @moduledoc """
  Represents a chat conversation in Messages.
  A chat can be a one-on-one conversation or a group chat.
  """

  alias Imessaged.Models.Contact

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          participants: [Contact.t()]
        }

  defstruct [:id, :name, :participants]
end
