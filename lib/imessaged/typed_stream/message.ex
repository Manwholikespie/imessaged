defmodule Imessaged.TypedStream.Message do
  @moduledoc """
  Represents a parsed TypedStream message structure.
  """

  defmodule Object do
    @moduledoc "Represents an NSObject in the TypedStream"
    defstruct [:class_name, :version, :data]
  end

  defmodule Class do
    @moduledoc "Represents a class definition in the TypedStream"
    defstruct [:name, :version]
  end

  defmodule Data do
    @moduledoc "Represents raw data in the TypedStream"
    defstruct [:values]
  end
end
