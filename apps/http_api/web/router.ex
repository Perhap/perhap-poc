defmodule HttpApi.Router do
  use HttpApi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HttpApi do
    pipe_through :api
    get "/:realm/keys", QueryController, :get_domain_keys
    get "/:realm/:domain/keys", QueryController, :get_entity_keys
    get "/:realm/:domain/:guid", QueryController, :distinguish_guid_type
    get "/:realm/:domain", QueryController, :query
    post "/:realm/:domain/:entity/:event_type", PublishController, :publish
  end
end
