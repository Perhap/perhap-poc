defmodule Cassandra do
  require Cqlerl.Structs
  require Logger
  require Poison

 def init do
    {:ok, client} = :cqerl.get_client({})
    [
      :cqerl.run_query(client, create_keyspace(keyspace)) |> handle_result,
      :cqerl.run_query(client, create_events_table(table)) |> handle_result
    ]
  end

  def publish %{domain: domain, entity: entity, type: type, event: event} do
    {:ok, client} = :cqerl.get_client({})
    :cqerl.run_query(client, insert_query(table, domain, entity, type, event)) |> handle_result
  end

  def query criteria do
    {:ok, client} = :cqerl.get_client({})
    updated_criteria = make_uuid(criteria)
    :cqerl.run_query(
      client,
      Cqlerl.Structs.cql_query(
        statement: make_select_statement(table, updated_criteria),
        values: updated_criteria
      )
    ) |> handle_result
  end

  def keyspace, do: Application.get_env(:cassandra, :keyspace)
  def table, do: Application.get_env(:cassandra, :keyspace) <> "." <> Application.get_env(:cassandra, :table)

  def make_uuid criteria do
    if Map.has_key?(criteria, :entity) do
      Map.merge(criteria, %{ entity: :uuid.string_to_uuid(criteria[:entity]) })
    else criteria
    end
  end

  def create_keyspace keyspace do
    """
    CREATE KEYSPACE IF NOT EXISTS #{keyspace}\
      WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };
    """
  end

  def create_events_table table do
    """
    CREATE TABLE IF NOT EXISTS #{table}
      ( domain varchar,
        type varchar,
        entity uuid,
        event_id timeuuid,
        event text,
        PRIMARY KEY (domain, type, entity, event_id))
        WITH CLUSTERING ORDER BY (type ASC, entity ASC, event_id DESC);
    """
  end

  def insert_query table, domain, entity, type, event do
    """
    INSERT INTO #{table}(domain, type, entity, event_id, event)
      VALUES ('#{domain}', '#{type}', #{entity}, now(), '#{Poison.encode!(event)}');
    """
  end

  def make_select_statement table, criteria do
    "SELECT event_id, domain, type, entity, dateOf(event_id) AS unixtime, event FROM #{table} WHERE " <>
    ( Enum.map(criteria, fn {k, _} -> "#{k}=?" end) |> Enum.join(" AND ") ) <>
    ";"
  end

  def handle_result {:ok, :void} do
    {:ok, :void}
  end

  def handle_result {:ok, {:cql_result, _column_spec, _result, _query, _ref} = result } do
    rows = :cqerl.all_rows result
    Enum.map rows, fn row ->
      Keyword.merge(row, [event_id: :uuid.uuid_to_string(row[:event_id])]) |>
      Keyword.merge([entity: :uuid.uuid_to_string(row[:entity])]) |>
      Keyword.merge([event: Poison.decode!(row[:event])])
    end
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
