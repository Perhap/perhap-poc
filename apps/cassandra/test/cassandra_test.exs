defmodule CassandraTest do
  use ExUnit.Case
  doctest Cassandra

  setup_all do
    Cassandra.init
    test_domain = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)
    test_realm = 'test'

    on_exit fn ->
      {:ok, client} = :cqerl.get_client()
      :cqerl.send_query(client, "DELETE FROM #{Cassandra.table} WHERE realm = '#{test_realm}' and domain = '#{test_domain}';")
    end

    [realm: test_realm, domain: test_domain]
  end

  test "stores and retrieves an event for a given entity", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity, type: "test", event: event})
    [stored_event] = Cassandra.query(%{entity: entity})
    assert event == stored_event[:event]
  end

  test "retrieves events following a given event for a given entity", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity, type: "test", event: %{which_event: "first"}})
    [stored_event] = Cassandra.query(%{entity: entity})
    entity2 = :uuid.uuid_to_string(:uuid.get_v4())
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity2, type: "test", event: %{which_event: "second"}})
    [stored_event2] = Cassandra.query(%{realm: context[:realm], domain: context[:domain], following: stored_event[:event_id]})
    assert stored_event2[:event]["which_event"] == "second"
  end

  test "retrieves a list of domains", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity, type: "test", event: event})
    domains = Cassandra.get_domain_keys(%{realm: context[:realm]})
    assert Enum.member?(domains, context[:domain])
  end

  test "retrieves a list of entities within a domain", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity, type: "test", event: event})
    entities = Cassandra.get_entity_keys(%{realm: context[:realm], domain: context[:domain]})
    assert Enum.member?(entities, entity)
  end

  test "retrieves all events within a domain", context do
    entity = :uuid.uuid_to_string(:uuid.get_v4())
    event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{realm: context[:realm], domain: context[:domain], entity: entity, type: "test", event: event})
    stored_events = Cassandra.query(%{realm: context[:realm], domain: context[:domain]})
                    |> Enum.map(fn row -> row[:event] end)
    assert Enum.member?(stored_events, event)
  end

end
