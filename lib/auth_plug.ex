defmodule AuthPlug do
  @moduledoc """
  `AuthPlug` handles all our auth needs in just a handful of lines of code.
  Please see `README.md` for setup instructions.
  """
  # https://hexdocs.pm/plug/readme.html#the-plug-conn-struct
  import Plug.Conn
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
    IO.inspect(options, label: "options")
    AuthPlug.Helpers.check_environment_vars()
    AuthPlug.Helpers.get_approles(options)
    options
  end

  @doc """
  `call/2` is invoked to handle each HTTP request which `auth_plug` protects.
  If the `conn` contains a valid JWT in Authentication Headers,
  jwt query parameter or Phoenix Session, then continue to the protected route,
  else redirect to the `auth_url` with the referer set as the continuation URL.
  """
  def call(conn, options) do

    jwt = get_jwt(conn)

    case AuthPlug.Token.verify_jwt(jwt) do
      {:ok, values} ->
        put_current_token(conn, jwt, values)

      # log the JWT verify error then redirect:
      {:error, reason} ->
        Logger.error(Kernel.inspect(reason))
        redirect_to_auth(conn, options)
    end
  end

  defp get_jwt(conn) do
    cond do
      # First Check for JWT in URL Query String.
      # We want a *new* session to supercede any expired session,
      #  so the check for JWT *before* anything else.
      conn.query_string =~ "jwt" ->
        query = URI.decode_query(conn.query_string)
        Map.get(query, "jwt")

      # Check for JWT in Headers:
      Enum.count(get_req_header(conn, "authorization")) > 0 ->
        conn.req_headers
        |> List.keyfind("authorization", 0)
        |> get_token_from_header()

      #  Check for Person in Plug.Conn.assigns
      Map.has_key?(conn.assigns, :jwt) && not is_nil(conn.assigns.jwt) ->
        conn.assigns.jwt

      # Check for Session in Plug.Session:
      not is_nil(get_session(conn, :jwt)) ->
        get_session(conn, :jwt)

      # By default return nil so auth check fails
      true ->
        nil
    end
  end

  def put_current_token(conn, jwt, values) do
    # convert map of string to atom: stackoverflow.com/questions/31990134
    claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
    # return the conn with the session
    create_session(conn, claims, jwt)
  end

  @doc """
  `create_session/2` takes a `conn`, claims and a JWT
  and creates the session using Phoenix Sessions
  and the JWT as the value so that it can be checked
  on each future request.
  Makes the decoded JWT available in conn.assigns
  which means it can be used in templates.
  """
  def create_session(conn, claims, jwt) do
    claims = AuthPlug.Helpers.strip_struct_metadata(claims)
    conn
    |> assign(:person, claims)
    |> assign(:jwt, jwt)
    |> put_session(:jwt, jwt)
    |> configure_session(renew: true)
  end

  @doc """
  `create_jwt_session/2` recieves a `conn` (Plug.Conn) and `claims`
  e.g: `%{email: "person@dwyl.com", id: 1}`.
  Signs a JWT which gets attached to the session.
  This is super-useful in testing as we
  can simply invoke
  `create_jwt_session(conn, %{email: "al@ex.co", id: 1})`
  and continue the request pipeline with a valid session.
  """
  def create_jwt_session(conn, claims) do
    jwt = claims # delete %Auth.Person github.com/dwyl/auth_plug/issues/16
      |> AuthPlug.Helpers.strip_struct_metadata()
      |> AuthPlug.Token.generate_jwt!()

    create_session(conn, claims, jwt)
  end

  #  fail fast if no JWT in auth header:
  defp get_token_from_header(nil), do: nil

  defp get_token_from_header({"authorization", value}) do
    value = String.replace(value, "Bearer", "") |> String.trim()
    # fast check for JWT format validity before slower verify:
    if is_nil(value) do # Does this ever eval to true?
      nil
    else
      case Enum.count(String.split(value, ".")) == 3 do
        false ->
          nil

        # appears to be valid JWT proceed to verifying it
        true ->
          value
      end
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
end
