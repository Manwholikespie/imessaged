defmodule Imessaged.RouterTest do
  use ExUnit.Case, async: true

  @base_url "http://localhost:4000"
  @req Req.new(base_url: @base_url, retry: false)

  setup_all do
    Application.ensure_all_started(:imessaged)
    :ok
  end

  test "GET / returns online status" do
    response = Req.get!(@req, url: "/")
    assert response.status == 200
    assert response.body == "online"
  end

  test "GET /messages returns list of messages" do
    query_params = %{"limit" => 10}
    response = Req.get!(@req, url: "/messages", params: query_params)
    [message | _] = response.body

    assert response.status == 200
    assert "text" in Map.keys(message)
  end
end
