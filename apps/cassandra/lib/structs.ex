defmodule Cqlerl.Structs do
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  defrecord :cql_query, extract(:cql_query, from_lib: "cqerl/include/cqerl.hrl")
end
