defmodule AuthPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    jwt =
      conn.req_headers
      |> List.keyfind("authorization", 0)
      |> get_token_from_header()

    validate_token(conn, jwt)
  end

  defp get_token_from_header(nil), do: nil

  defp get_token_from_header({"authorization", value}) do
    # regex check value start with Bearer follow by a space and any characters
    case Regex.run(~r/^Bearer\s(.*)/, value) do
      [_, jwt] -> jwt
      _ -> nil
    end
  end

  defp validate_token(conn, nil), do: unauthorized(conn)

  defp validate_token(conn, jwt) do

  end
    case AuthMvp.Token.verify_and_validate(jwt) do
      {:ok, values} ->
        # convert map of string to atom: stackoverflow.com/questions/31990134
        claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
        assign(conn, :claims, claims)
      {:error, _} -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer realm=\"Person access\"")
    |> send_resp(401, "unauthorized")
    |> halt()
  end
end
