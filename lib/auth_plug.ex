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
    options
  end

  @doc """
  `call/2` is invoked to handle each HTTP request which `auth_plug` protects.
  If the `conn` contains a valid JWT in Authentication Headers,
  jwt query parameter or Phoenix Session, then continue to the protected route,
  else redirect to the `auth_url` with the referer set as the continuation URL.
  """
  def call(conn, options) do
    # Setup Plug.Session
    conn = setup_session(conn)

    # Locate JWT so we can attempt to verify it:
    jwt =
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
        Map.has_key?(conn.assigns, :person) && not is_nil(conn.assigns.person) ->
          conn.assigns.person

        # Check for Session in Plug.Session:
        not is_nil(get_session(conn, :person)) ->
          get_session(conn, :person)

        # By default return nil so auth check fails
        true ->
          nil
      end

    validate_token(conn, jwt, options)
  end

  @doc """
  `session_options/0` returns the list of Phoenix/Plug Session options.
  This is useful if you need to check them or use them somewhere else.
  """
  def session_options() do
    [
      store: :cookie,
      key: "_auth_key",
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      signing_salt: AuthPlug.Token.client_secret
    ]
  end

  @doc """
  `setup_session/1` configures the Phoenix/Plug Session.
  """
  def setup_session(conn) do
    conn = put_in(conn.secret_key_base, System.get_env("SECRET_KEY_BASE"))

    opts = session_options() |> Plug.Session.init()

    conn
    |> Plug.Session.call(opts)
    |> fetch_session()
    |> configure_session(renew: true)
  end

  @doc """
  `create_session/2` takes a `conn`, claims and a JWT
  and creates the session using Phoenix Sessions
  and the JWT as the value so that it can be checked
  on each future request.
  """
  def create_session(conn, claims, jwt) do
    conn
    |> assign(:decoded, claims)
    |> assign(:person, jwt)
    |> put_session(:person, jwt)
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
    jwt = claims
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)
      |> AuthPlug.Token.generate_jwt!()
    conn
      |> setup_session()
      |> create_session(claims, jwt)
  end

  #  fail fast if no JWT in auth header:
  defp get_token_from_header(nil), do: nil

  defp get_token_from_header({"authorization", value}) do
    value = String.replace(value, "Bearer", "") |> String.trim()
    # fast check for JWT format validity before slower verify:
    if is_nil(value) do
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

  # if jwt is nil fail fast
  defp validate_token(conn, nil, opts), do: redirect_to_auth(conn, opts)

  # attempt to validate a valid-looking JWT:
  defp validate_token(conn, jwt, opts) do
    case AuthPlug.Token.verify_jwt(jwt) do
      {:ok, values} ->
        # convert map of string to atom: stackoverflow.com/questions/31990134
        claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
        # return the conn with the session
        create_session(conn, claims, jwt)

      # log the JWT verify error then redirect:
      {:error, reason} ->
        Logger.error(Kernel.inspect(reason))
        redirect_to_auth(conn, opts)
    end
  end

  # redirect to auth_url with referer to resume once authenticated:
  defp redirect_to_auth(conn, opts) do
    baseurl = AuthPlug.Helpers.get_baseurl_from_conn(conn)

    to =
      opts.auth_url <>
        "?referer=" <>
        URI.encode(baseurl <> conn.request_path) <>
        "&client_id=" <> AuthPlug.Token.client_id()

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
