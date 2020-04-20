defmodule AuthPlug.Endpoint do
  use Phoenix.Endpoint, otp_app: :auth_plug

  @session_options [
    store: :cookie,
    key: "_auth_key",
    signing_salt: "aDYyYPIr"
  ]
  plug Plug.Session, @session_options
end
