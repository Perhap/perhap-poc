defmodule QueryControllerTest do
  use HttpApi.ConnCase, async: true
  alias Cassandra

  setup_all do
    test_realm = 'test'
    test_domain = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)
    test_entity = :uuid.uuid_to_string(:uuid.get_v4())
    test_event = %{"event" => :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)}
    {:ok, _} = Cassandra.publish(%{realm: test_realm, domain: test_domain, entity: test_entity, type: "test", event: test_event})

    on_exit fn ->
      {:ok, client} = :cqerl.get_client()
      :cqerl.send_query(client, "DELETE FROM #{Cassandra.table} WHERE realm = '#{test_realm}' and domain = '#{test_domain}';")
    end

    [realm: test_realm, domain: test_domain, entity: test_entity, event: test_event]
  end

  test "we can retrieve entity keys", context do
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> get("/#{context[:realm]}/#{context[:domain]}/keys")
    assert Enum.member?(json_response(conn, 200), context[:entity])
  end

  test "we can retrieve an empty map if entity keys don't exist", context do
    bad_domain = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> get("/#{context[:realm]}/#{bad_domain}/keys")
    assert json_response(conn, 200) == []
  end

  test "we can retrieve domain keys", context do
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> get("/#{context[:realm]}/keys")
    assert Enum.member?(json_response(conn, 200), context[:domain])
  end

  test "we can retrieve an empty map if domain keys don't exist", _context do
    bad_realm = :crypto.strong_rand_bytes(24) |> Base.url_encode64 |> binary_part(0, 24)
    conn = build_conn()
    |> put_req_header("accept", "application/json")
    |> get("/#{bad_realm}/keys")
    assert json_response(conn, 200) == []
  end

end
