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
  @httpoison (Application.compile_env(:auth_plug, :httpoison_mock) && AuthPlug.HTTPoisonMock) ||
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
    to = get_auth_url(conn)

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
  receives a `conn` (Plug.Conn) and unsets the session.
  This is super-useful in testing as we can easily reset a session.
  """
  def logout(conn) do
    # stackoverflow.com/questions/42325996/delete-assigns
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
    |> assign(:loggedin, false)
  end

  @doc """
  `assign_jwt_to_socket/3` assigns a 'person' object containing information
  about the authenticated person to the socket
  in case the jwt parse is successful.
  It raises an error if jwt is not valid.
  This function is especially handy with LiveView.
  Invoke this as:
  socket = socket
    |> AuthPlug.assign_jwt_to_socket(&Phoenix.LiveView.assign_new/3, jwt)
  `socket` is the first argument to `assign_jwt_to_socket/3` so it's chainable.
  """
  def assign_jwt_to_socket(socket, assign_new, jwt) do
    claims =
      jwt
      |> AuthPlug.Token.verify_jwt!()
      |> AuthPlug.Helpers.strip_struct_metadata()
      |> Useful.atomize_map_keys()

    socket =
      socket
      #  Pass function by reference in Elixir:
      # stackoverflow.com/a/22562288/1148249
      |> assign_new.(:person, fn -> claims end)
      |> assign_new.(:loggedin, fn -> true end)

    socket
  end

  # `parse_body_response/1` parses the REST HTTP response
  # so your app can use the resulting JSON.
  defp parse_body_response(response) do
    body = Map.get(response, :body)
    {:ok, str_key_map} = Jason.decode(body)

    {:ok, Useful.atomize_map_keys(str_key_map)}
  end

  # Send query to auth app to end session.
  # Returns tuple with status code and message
  def end_session_auth(auth_url) do
    with {:ok, response} <- @httpoison.post(auth_url, ''),
         {:status_code, 200} <- {:status_code, response.status_code} do
      {:ok, res} = parse_body_response(response)
      {200, res.message}
    else
      {:status_code, status_code} ->
        {status_code, "status code: #{status_code}"}

      {:error, _httpoison_error} ->
        {400, "The request to the auth app failed"}
    end
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

    {status_code, message} =
      end_session_auth("#{auth_url}/end_session/#{client_id}/#{claims.sid}/")

    resp(conn, status_code, message)
  end

  @doc """
  `get_auth_url/2` returns a string representing
  the auth url.
  The first parameter is `conn`,
  the second is optional and represents
  the endpoint in your application where the auth application will
  redirect to after authentication.
  By default the second parameter value is `conn.request_path` which represents
  the current path.

  ## Examples

  iex> AuthPlug.get_auth_url(conn)
  "https://dwylauth.herokuapp.com/?referer=https://www.example.com/&auth_client_id=123123"

  iex> AuthPlug.get_auth_url(conn, "/mypage)
  "https://dwylauth.herokuapp.com/?referer=https://www.example.com/mypage&auth_client_id=123123"
  """
  def get_auth_url(conn, redirect_to \\ nil) do
    auth_url = AuthPlug.Token.auth_url()
    request_path = redirect_to || conn.request_path

    referer =
      conn
      |> AuthPlug.Helpers.get_baseurl_from_conn()
      |> Kernel.<>(request_path)
      |> URI.encode()

    client_id = AuthPlug.Token.client_id()

    "#{auth_url}?referer=#{referer}&auth_client_id=#{client_id}"
  end
end
