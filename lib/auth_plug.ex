defmodule AuthPlug do
  @moduledoc """
  `AuthPlug` handles all our auth needs in just a handful of lines of code.
  Please see `README.md` for setup instructions.
  """
  # https://hexdocs.pm/plug/readme.html#the-plug-conn-struct
  import Plug.Conn, only: [halt: 1, put_resp_header: 3, resp: 3]
  # https://hexdocs.pm/logger/Logger.html
  require Logger

  @doc """
  `init/1` initialises the options passed in and makes them
  available in the lifecycle of the `call/2` invocation (below).
  We pass in the `auth_url` key/value with the URL of the Auth service
  to redirect to if session is invalid/expired.
  """
  def init(options) do
    # return options unmodified
    AuthPlug.Helpers.check_environment_vars()
    options
  end

  @doc """
  `call/2` is invoked to handle each HTTP request which `auth_plug` protects.
  If the `conn` contains a valid JWT in Authentication Headers,
  jwt query parameter or Phoenix Session, then continue to the protected route,
  else redirect to the `auth_url` with the referer set as the continuation URL.
  """
  def call(conn, options) do

    jwt = AuthPlug.Token.get_jwt(conn)

    case AuthPlug.Token.verify_jwt(jwt) do
      {:ok, values} ->
        AuthPlug.Token.put_current_token(conn, jwt, values)

      # log the JWT verify error then redirect:
      {:error, reason} ->
        Logger.error("AuthPlug: " <> Kernel.inspect(reason))
        redirect_to_auth(conn, options)
    end
  end

  # redirect to auth_url with referer to resume once authenticated:
  defp redirect_to_auth(conn, opts) do
    baseurl = AuthPlug.Helpers.get_baseurl_from_conn(conn)

    to =
      opts.auth_url <>
        "?referer=" <>
        URI.encode(baseurl <> conn.request_path) <>
        "&auth_client_id=" <> AuthPlug.Token.client_id()

    # gotta tell the browser to temporarily redirect to the auth_url with 302
    status = 302

    conn
    # redirect to auth_url
    |> put_resp_header("location", to)
    # only our tests see this.
    |> resp(status, "unauthorized")
    # halt the conn so no further processing is done.
    |> halt()
  end

  # Proxy function for to avoid breaking existing apps that rely on this:
  def create_jwt_session(conn, claims) do
    AuthPlug.Token.create_jwt_session(conn, claims)
  end
end
