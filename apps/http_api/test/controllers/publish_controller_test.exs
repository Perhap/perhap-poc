defmodule PublishControllerTest do
  use HttpApi.ConnCase, async: true

  test "we can publish an event" do
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> post("/test/domain/#{:uuid.get_v4() |> :uuid.uuid_to_string}/test", [event: "test data"])
    assert response(conn, 200)
  end
  
  test "an entity that's not a v4 UUID gets a 400 error" do
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> post("/test/domain/not-a-UUID/test", [event: "test data"])
    assert response(conn, 400)
  end

  test "data without 'event' gets a 400 error" do
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> post("/test/domain/#{:uuid.get_v4() |> :uuid.uuid_to_string}/test", [not_event: "test data"])
    assert response(conn, 400)
  end
end
