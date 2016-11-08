defmodule CassandraTest do
  use ExUnit.Case
  doctest Cassandra

  test "stores and retrieves an event" do
    event = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)
    event_id = Cassandra.publish(%{domain: "test", root: "test", event_type: "test", event: event})
    stored_event = Cassandra.query(%{event_id: event_id})
    assert event == stored_event
  end
end
