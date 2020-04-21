defmodule AuthPlug do
  import Plug.Conn

  @secret System.get_env("SECRET_KEY_BASE")
  @signer Joken.Signer.create("HS256", @secret)

  def init(opts) do
    opts
  end

  def call(conn, _params) do
    # IO.inspect(conn, labels: "conn:13")
    # IO.inspect(params, label: "params:14")
    IO.inspect(conn.query_string, label: "conn.query_string:15")
    IO.inspect(conn.query_string =~ "jwt", label: "=~")
    # IO.inspect(conn.assigns, label: "conn.assigns:17")
    # IO.inspect(conn.assigns.person, label: "conn.assigns.person:18")
    # query = URI.decode_query(conn.query_string)
    # IO.inspect(query, label: "query")
    # IO.inspect(get_req_header(conn, "authorization"), label: "21")

    # Setup Plug.Session
    conn = setup_session(conn)

    # Locate JWT so we can attempt to verify it:
    jwt = cond do

      #  Check for Person in Plug.Conn.assigns
      Map.has_key?(conn.assigns, :person) && not is_nil(conn.assigns.person) ->
        # IO.inspect(conn.assigns.person, label: "conn.assigns.person")
        conn.assigns.person

      # Check for Session in Plug.Session:
      not is_nil(get_session(conn, :person)) ->
        # IO.inspect(get_session(conn, :person), label: "get_session(conn, :person)")
        get_session(conn, :person)

      # Check for JWT in URL Query String:
      conn.query_string =~ "jwt" ->
        query = URI.decode_query(conn.query_string)
        # IO.inspect(query, label: "query")
        Map.get(query, "jwt")

      # Check for JWT in Headers:
      Enum.count(get_req_header(conn, "authorization")) > 0 ->
        conn.req_headers
          |> List.keyfind("authorization", 0)
          |> get_token_from_header()


      # By default return nil so auth check fails
      true ->
        IO.inspect("cond true:54")
        nil

    end
    IO.inspect(jwt, label: "jwt:31")
    validate_token(conn, jwt)
  end


  def setup_session(conn) do
    conn = put_in(conn.secret_key_base, System.get_env("SECRET_KEY_BASE"))

    opts =
      Plug.Session.init(
        store: :cookie,
        key: "_auth_key",
        secret_key_base: @secret,
        signing_salt: @secret
      )

    conn
    |> Plug.Session.call(opts)
    |> fetch_session()
    |> configure_session(renew: true)
  end

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

  defp validate_token(conn, nil), do: unauthorized(conn)

  defp validate_token(conn, jwt) do
    IO.inspect(jwt, label: "jwt:102")
    IO.inspect(@signer, label: "@signer:103")
    IO.inspect(AuthPlug.Token.verify(jwt, @signer), label: "verify:104")
    case AuthPlug.Token.verify_and_validate(jwt, @signer) do
      {:ok, values} ->
        # convert map of string to atom: stackoverflow.com/questions/31990134
        claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
        conn
        |> assign(:decoded, claims)
        |> assign(:person, jwt)
        |> put_session(:person, jwt)

      {:error, reason} ->
        IO.inspect(reason, label: ":error reason:")
        unauthorized(conn)
    end
  end

  # def extract(conn, params) do
  #
  # end

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer realm=\"Person access\"")
    |> send_resp(401, "unauthorized:124")
    |> halt()
  end
end
