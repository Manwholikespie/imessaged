defmodule Imessaged.Models.Contact do
  @moduledoc """
  Represents a contact (buddy) in the Messages system.
  This could be someone with an email address or phone number.
  """

  @type t :: %__MODULE__{
          handle: String.t()
        }

  defstruct [:handle]
end
