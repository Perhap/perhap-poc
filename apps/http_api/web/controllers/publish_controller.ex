defmodule HttpApi.PublishController do
  use HttpApi.Web, :controller
  alias Cassandra

  def publish(conn, %{"realm" => realm, "domain" => domain, "entity" => entity, "event_type" => event_type, "event" => event}) do
    try do
      :uuid.is_v4(:uuid.string_to_uuid(entity))
      _publish(conn, %{"realm" => realm, "domain" => domain, "entity" => entity, "event_type" => event_type, "event" => event})
    catch 
      :exit, _ -> _badarg conn
    end
  end

  def publish conn, _data do
    _badarg conn
  end

  defp _publish(conn, %{"realm" => realm, "domain" => domain, "entity" => entity, "event_type" => event_type, "event" => event}) do
      Cassandra.init
      Cassandra.publish %{realm: realm, domain: domain, entity: entity, type: event_type, event: event}
      conn |> send_resp(200, "")
  end

  defp _badarg conn do
    conn |> send_resp(400, "Bad argument. Publish expects POST /[realm]/[domain]/[entity's v4 UUID]/[event_type] with a json element 'event'")
  end
end
