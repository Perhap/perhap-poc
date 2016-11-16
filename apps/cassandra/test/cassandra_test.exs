defmodule CassandraTest do
  use ExUnit.Case
  doctest Cassandra

  test "stores and retrieves an event" do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{domain: "test", entity: entity, type: "test", event: event})
    [stored_event] = Cassandra.query(%{domain: "test", type: "test", entity: entity})
    assert event == stored_event[:event]
  end
end
