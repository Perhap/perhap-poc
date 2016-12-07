use Mix.Config
alias Poison

config :cassandra,
  nodes: System.get_env("CASSANDRA_NODES") || ~s( { "nodes": [ { "ip": "127.0.0.1", "port": 9042 } ] } ),
  auth_handler: System.get_env("CASSANDRA_AUTH_HANDLER") || :cqerl_auth_plain_handler,
  user: System.get_env("CASSANDRA_USER") || "perhap",
  pass: System.get_env("CASSANDRA_PASS") || "test_cluster",
  keyspace: System.get_env("CASSANDRA_KEYSPACE") || "perhap",
  table: System.get_env("CASSANDRA_TABLE") || "events"
