defmodule Imessaged.RouterTest do
  use ExUnit.Case, async: true

  @base_url "http://localhost:4000"

  setup_all do
    Application.ensure_all_started(:imessaged)
    :ok
  end

  test "GET / returns online status" do
    response = Req.get!(@base_url <> "/")
    assert response.status == 200
    assert response.body == "online"
  end

  test "GET /messages returns list of messages" do
    response = Req.get!(@base_url <> "/messages")
    [message | _] = response.body

    assert response.status == 200
    assert "content" in Map.keys(message)
  end
end
