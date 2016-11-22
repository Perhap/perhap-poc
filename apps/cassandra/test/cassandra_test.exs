defmodule CassandraTest do
  use ExUnit.Case
  doctest Cassandra

  setup_all do
    Cassandra.init
    test_domain = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)

    on_exit fn ->
      {:ok, client} = :cqerl.get_client({})
      :cqerl.send_query(client, "DELETE FROM #{Cassandra.table} WHERE domain = '#{test_domain}';")
    end
    [domain: test_domain]
  end

  test "stores and retrieves an event", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{domain: context[:domain], entity: entity, type: "test", event: event})
    [stored_event] = Cassandra.query(%{domain: context[:domain], entity: entity})
    assert event == stored_event[:event]
  end

  test "retrieves events following a given event", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    {:ok, _} = Cassandra.publish(%{domain: context[:domain], entity: entity, type: "test", event: %{which_event: "first"}})
    [stored_event] = Cassandra.query(%{domain: context[:domain], entity: entity})
    entity2 = :uuid.uuid_to_string(:uuid.get_v4())
    {:ok, _} = Cassandra.publish(%{domain: context[:domain], entity: entity2, type: "test", event: %{which_event: "second"}})
    [stored_event2] = Cassandra.query(%{domain: context[:domain], following: stored_event[:event_id]})
    assert stored_event2[:event]["which_event"] == "second"
  end

end
