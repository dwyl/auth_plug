defmodule AuthPlug.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  use Application
  require Logger
  @data %{email: "alexa@gmail.com", name: "Alexa"}
  @jwt AuthPlug.Token.generate_jwt!(@data)

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: AuthPlug.Router, options: [port: 4000]}
    ]

    Logger.info("First visit: http://localhost:4000/admin")
    Logger.info("Then visit: http://localhost:4000/admin?jwt=" <> @jwt)
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
