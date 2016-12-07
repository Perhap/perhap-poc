defmodule Cassandra do
  require Cqlerl.Structs
  require Logger
  import Poison, only: [encode!: 1, decode!: 1]

  def nodes do
    Map.get( ( Application.get_env(:cassandra, :nodes) |> decode! ), "nodes")
    |> Enum.map( fn node -> { node["ip"], node["port"] } end )
  end

  def creds do
    { :auth,
      { Application.get_env(:cassandra, :auth_handler),
        [ { Application.get_env(:cassandra, :user), Application.get_env(:cassandra, :pass) } ] 
      }
    }
  end

  def keyspace, do: Application.get_env(:cassandra, :keyspace)

  def table, do: Application.get_env(:cassandra, :keyspace) <> "." <> Application.get_env(:cassandra, :table)

 def init do
   :ok = :cqerl_cluster.add_nodes( nodes, [ creds ] )
   {:ok, client} = :cqerl.get_client()
   [
     :cqerl.run_query(client, create_keyspace) |> handle_result,
     :cqerl.run_query(client, create_events_table) |> handle_result,
     :cqerl.run_query(client, create_entity_index) |> handle_result
   ]
  end

  def publish %{realm: realm, domain: domain, entity: entity, type: type, event: event} do
    {:ok, client} = :cqerl.get_client()
    :cqerl.run_query(client, insert_query(realm, domain, entity, type, event)) |> handle_result
  end

  def query criteria do
    {:ok, client} = :cqerl.get_client()
    :cqerl.run_query(
      client,
      Cqlerl.Structs.cql_query(
        statement: make_select_statement(criteria),
        values: make_where(criteria),
        page_size: 1000
      )
    ) |> handle_result
  end

  def get_domain_keys %{realm: realm} do
    {:ok, client} = :cqerl.get_client()
    :cqerl.run_query(client, make_domain_keys_query(realm)) |>
      handle_result |>
      deduplicate
  end

  def get_entity_keys %{realm: realm, domain: domain} do
    {:ok, client} = :cqerl.get_client()
    :cqerl.run_query(client, make_entity_keys_query(realm, domain)) |>
    handle_result |>
    deduplicate |>
    Enum.map(fn entity -> :uuid.uuid_to_string entity end)
  end

  def deduplicate l do
    l |> 
      Enum.uniq |>
      Enum.map(fn x -> Keyword.values x end) |>
      List.flatten
  end

  def create_keyspace do
    """
    CREATE KEYSPACE IF NOT EXISTS #{keyspace}\
      WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };
    """
  end

  def create_events_table do
    """
    CREATE TABLE IF NOT EXISTS #{table}
      ( realm varchar,
        domain varchar,
        event_id timeuuid,
        entity uuid,
        type varchar,
        event text,
        PRIMARY KEY (realm, domain, event_id, entity))
        WITH CLUSTERING ORDER BY (domain ASC, event_id DESC);
    """
  end

  def create_entity_index do
    """
    CREATE INDEX IF NOT EXISTS on #{table} (entity);
    """
  end

  def create_event_id_index do
    """
    CREATE INDEX IF NOT EXISTS on #{table} (event_id);
    """
  end

  def insert_query realm, domain, entity, type, event do
    """
    INSERT INTO #{table}(realm, domain, type, entity, event_id, event)
      VALUES ('#{realm}', '#{domain}', '#{type}', #{entity}, now(), '#{encode!(event)}');
    """
  end

  def make_select_statement criteria do
    "SELECT event_id, realm, domain, type, entity, dateOf(event_id) AS unixtime, event FROM #{table} WHERE " <>
    ( Enum.map(criteria, fn {k, _} -> 
      case k do
        :following -> "event_id > ?"
        _ -> "#{k} = ?"
      end
    end ) |> Enum.join(" AND ") ) <> ";"
  end

  def make_where criteria do
    if Map.has_key?(criteria, :following) do
      Map.merge(criteria, %{ event_id: criteria[:following] })
    else
      criteria
    end
  end

  def make_domain_keys_query realm do
    """
    SELECT domain FROM #{table} WHERE realm = '#{realm}';
    """
  end

  def make_entity_keys_query realm, domain do
    """
    SELECT entity FROM #{table} WHERE realm = '#{realm}' AND domain = '#{domain}';
    """
  end

  def handle_result {:ok, {:cql_result, column_spec, _result, _query, _ref} = result } do
    rows = :cqerl.all_rows result
    columns = Enum.map column_spec, fn column ->
      elem column, 3
    end
    cond do
      Enum.all?([:domain, :event_id, :entity, :event, :type], fn column -> Enum.member?(columns, column) end) ->
        Enum.map rows, fn row -> 
          Keyword.merge(row, [event_id: :uuid.uuid_to_string(row[:event_id])]) |>
          Keyword.merge([entity: :uuid.uuid_to_string(row[:entity])]) |>
          Keyword.merge([event: decode!(row[:event])])
        end
      True ->
        rows
    end
  end

  def handle_result {:ok, :void} do
    {:ok, :void}
  end

  def handle_result {:ok, result} do
    Logger.debug "Cassandra message: #{inspect result}"
    {:ok, result}
  end

  def handle_result result do
    Logger.warn "Cassandra error: #{inspect result}"
    {:error, result}
  end

end
