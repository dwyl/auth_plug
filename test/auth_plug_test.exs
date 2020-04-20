defmodule AuthPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias AuthPlug.Token
  @secret System.get_env("SECRET_KEY_BASE")
  @signer Joken.Signer.create("HS256", @secret)

  test "Plug init function doesn't change params" do
    assert AuthPlug.init(%{}) == %{}
  end

  test "Plug return 401 wiht not Authorization Header" do
    conn = AuthPlug.call(conn("/admin", ""), %{})

    assert conn.status == 401
  end

  test "Plug return 401 wiht incorrect jwt header" do
    conn =
      conn("/admin", "")
      |> put_req_header("authorization", "Bearer incorrect.jwt")
      |> AuthPlug.call(%{})

    assert conn.status == 401
  end

  test "Fail when authorization header token is invalid" do
    conn =
      conn("/admin", "")
      |> put_req_header("authorization", "Bearer this.will.fail")
      |> AuthPlug.call(%{})

    assert conn.status == 401
  end

  test "Conn.assign person" do
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = Token.generate_and_sign!(data, @signer)
    # IO.inspect(jwt, label: "jwt:39")

    conn =
    conn("get", "/admin", "")
      |> assign(:person, data)
      |> AuthPlug.call(%{})

    assert conn.assigns.person.email == "alex@dwyl.com"
  end

  test "get_session(conn, :person)"do
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = Token.generate_and_sign!(data, @signer)
    # IO.inspect(jwt, label: "jwt:39")

    conn = conn("get", "/admin", "")
      |> AuthPlug.call(%{})
      


    token = get_session(conn, :person)

    {:ok, decoded} = AuthPlug.Token.verify_and_validate(token, @signer)

    assert decoded.email == "alex@dwyl.com"
  end

  test "Plug assigns claims to conn with valid jwt" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_and_sign!(data, @signer)
    IO.inspect(jwt, label: "jwt:39")

    conn =
      conn("/admin", "")
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> AuthPlug.call(%{})

    assert conn.assigns.person.email == "person@dwyl.com"
  end
end
