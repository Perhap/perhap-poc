defmodule HttpApi.QueryController do
  use HttpApi.Web, :controller
  alias Cassandra

  def distinguish_guid_type _conn, _data do
  end

  def query _conn, _data do
  end

  def get_domain_keys conn, %{"realm" => realm} do
    Cassandra.init
    json(conn, Cassandra.get_domain_keys(%{realm: realm}))
  end

  def get_entity_keys conn, %{"realm" => realm, "domain" => domain} do
    Cassandra.init
    json(conn, Cassandra.get_entity_keys(%{realm: realm, domain: domain}))
  end

end
