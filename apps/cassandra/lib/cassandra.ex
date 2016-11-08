defmodule Cassandra do
  require Logger
  require Poison

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

  def init do
    {:ok, client} = :cqerl.get_client({})
    keyspace_query = :cqerl.send_query(client, create_keyspace(Application.get_env(:cassandra, :keyspace)))
    receive do
      {:result, keyspace_query, :void} -> :ok
      {:result, keyspace_query, result} -> Logger.info "Cassandra keyspace setup: #{inspect result}"
      result -> Logger.warn "Cassandra error: #{inspect result}"
    end
    table_query = :cqerl.send_query(client, create_events_table(Application.get_env(:cassandra, :keyspace) <> "." <> Application.get_env(:cassandra, :table)))
    receive do
      {:result, table_query, :void} -> :ok
      {:result, table_query, result} -> Logger.info "Cassandra table setup: #{inspect result}"
      result -> Logger.warn "Cassandra error: #{inspect result}"
    end
  end

  def publish %{domain: domain, entity: entity, type: type, event: event} do
    table = Application.get_env(:cassandra, :keyspace) <> "." <> Application.get_env(:cassandra, :table)
    {:ok, client} = :cqerl.get_client({})
    Logger.debug insert_query(table, domain, entity, type, event)
    publish_query = :cqerl.send_query(client, insert_query(table, domain, entity, type, event))
    receive do
      {:result, publish_query, :void} -> :ok
      {:result, publish_query, result} -> Logger.debug "Cassandra insert query: #{inspect result}"
      result -> Logger.warn "Cassandra error: #{inspect result}"
    end
  end

  def query event do
  end
end
