defmodule AuthPlug do
  import Plug.Conn

  @signer Joken.Signer.create("HS256", "secret")
  @secret System.get_env("SECRET_KEY_BASE")

  def init(opts), do: opts

  def call(conn, _params) do
    # Setup Plug.Session
    conn = setup_session(conn)

    #  Check for Person in Plug.Conn.assigns

    # Check for Session in Plug.Session

    # Check for JWT in Headers or URL

    # Extract JWT

    # check for Phoenix Session
    conn = conn |> assign(:person, "alex")

    # IO.inspect(conn.assigns[:person])
    # conn = put_session(conn, :message, "new stuff we just set in the session")
    # message = get_session(conn, :message)
    # session = get_session(conn, :message)
    # IO.inspect(session, label: "session")

    # check for JWT in Headers:

    jwt =
      conn.req_headers
      |> List.keyfind("authorization", 0)
      |> get_token_from_header()

    conn
    # validate_token(conn, jwt)
  end

  defp setup_session(conn) do
    conn = put_in(conn.secret_key_base, System.get_env("SECRET_KEY_BASE"))

    opts =
      Plug.Session.init(
        store: :cookie,
        key: "_auth_key",
        secret_key_base: @secret,
        secret: @secret,
        signing_salt: @secret
      )

    conn
    |> Plug.Session.call(opts)
    |> fetch_session()
    |> configure_session(renew: true)
    |> put_session(:foo, "Alexa")
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
    case AuthPlug.Token.verify_and_validate(jwt, @signer) do
      {:ok, values} ->
        # convert map of string to atom: stackoverflow.com/questions/31990134
        claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
        assign(conn, :claims, claims)

      {:error, _} ->
        unauthorized(conn)
    end
  end

  # def extract(conn, params) do
  #
  # end

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer realm=\"Person access\"")
    |> send_resp(401, "unauthorized")
    |> halt()
  end
end
