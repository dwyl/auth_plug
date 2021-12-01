defmodule AuthPlug do
  @moduledoc """
  `AuthPlug` handles all our auth needs in just a handful of lines of code.
  Please see `README.md` for setup instructions.
  """
  # https://hexdocs.pm/plug/readme.html#the-plug-conn-struct
  import Plug.Conn,
    only: [
      assign: 3,
      clear_session: 1,
      configure_session: 2,
      delete_session: 2,
      halt: 1,
      put_resp_header: 3,
      resp: 3
    ]

  # https://hexdocs.pm/logger/Logger.html
  require Logger

  # Moch HTTPoison requests in Dev/Test, see: https://github.com/dwyl/elixir-auth-google/issues/35
  @httpoison (Application.get_env(:auth_plug, :httpoison_mock) && AuthPlug.HTTPoisonMock) ||
               HTTPoison

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
  def call(conn, _options) do
    jwt = AuthPlug.Token.get_jwt(conn)

    case AuthPlug.Token.verify_jwt(jwt) do
      {:ok, values} ->
        AuthPlug.Token.put_current_token(conn, jwt, values)

      # log the JWT verify error then redirect:
      {:error, reason} ->
        Logger.error("AuthPlug: " <> Kernel.inspect(reason))
        redirect_to_auth(conn)
    end
  end

  # redirect to auth_url with referer to resume once authenticated:
  defp redirect_to_auth(conn) do
    baseurl = AuthPlug.Helpers.get_baseurl_from_conn(conn)
    auth_url = AuthPlug.Token.auth_url()

    to =
      auth_url <>
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

  @doc """
  `logout/1` does exactly what you expect; logs the person out of your app.
  recieves a `conn` (Plug.Conn) and unsets the session.
  This is super-useful in testing as we can easily reset a session.
  """
  def logout(conn) do
    # https://stackoverflow.com/questions/42325996/delete-assigns
    conn = update_in(conn.assigns, &Map.drop(&1, [:jwt, :person]))

    conn
    # see below. makes REST API req to auth_url/end_session
    |> end_session()
    # hexdocs.pm/plug/Plug.Conn.html#delete_session/2,
    |> delete_session(:jwt)
    # hexdocs.pm/plug/Plug.Conn.html#clear_session/1
    |> clear_session()
    #  stackoverflow.com/questions/30999176
    |> configure_session(drop: true)
    |> assign(:state, "logout")
    |> resp(200, "logged out")
  end

  # `parse_body_response/1` parses the REST HTTP response
  # so your app can use the resulting JSON.
  defp parse_body_response({:ok, response}) do
    body = Map.get(response, :body)
    {:ok, str_key_map} = Jason.decode(body)

    {:ok, Useful.atomize_map_keys(str_key_map)}
  end

  @doc """
  `end_session/1` makes an HTTP Request to the auth_url 
  to end the session. This in turn makes the update on the auth app
  to update the session.end so the owner of the "consumer" app
  knows when the person logged out.
  `end_session/1` is invoked by `AuthPlug.logout/1` (above) 
  which will likely be the function called in practice.
  """
  def end_session(conn) do
    auth_url = AuthPlug.Token.auth_url()
    client_id = AuthPlug.Token.client_id()
    jwt = AuthPlug.Token.get_jwt(conn)

    {:ok, claims_strs} = AuthPlug.Token.verify_jwt(jwt)
    claims = Useful.atomize_map_keys(claims_strs)

    # Make the actual HTTP Requet to auth_url/end_session/etc:
    {:ok, response} =
      "#{auth_url}/end_session/#{client_id}/#{claims.sid}/"
      |> @httpoison.post('')
      |> parse_body_response()

    conn
    |> resp(200, response.message)
  end
end
