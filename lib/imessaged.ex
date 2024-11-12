defmodule Imessaged do
  alias Imessaged.Native

  def hello do
    Native.hello_nif()
  end
end
