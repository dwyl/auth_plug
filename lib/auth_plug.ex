defmodule AuthPlug do
  import Plug.Conn
  # import Phoenix.Controller

  @signer Joken.Signer.create("HS256", "secret")


  def init(opts), do: opts

  def call(conn, _params) do
#
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

  defp get_token_from_header(nil), do: nil

  defp get_token_from_header({"authorization", value}) do
    value = String.replace(value, "Bearer", "") |> String.trim()
    if is_nil(value) do
      nil

    else # fast check for JWT format validity before slower verify:
      case Enum.count(String.split(value, ".")) == 3 do
        false ->
          nil

        true -> # appears to be valid JWT proceed to verifying it
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
      {:error, _} -> unauthorized(conn)
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
