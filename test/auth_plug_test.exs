defmodule AuthPlugTest do
  use ExUnit.Case
  use Plug.Test
  alias AuthPlug.Token
  @opts AuthPlug.init(%{auth_url: "https://dwylauth.herokuapp.com"})

  test "Plug init function doesn't change params" do
    assert AuthPlug.init(%{}) == %{}
  end

  test "Plug return 401 wiht not Authorization Header" do
    conn = AuthPlug.call(conn(:get, "/admin"), @opts)

    # redirect when auth fails
    assert conn.status == 302
  end

  test "Plug return 401 wiht incorrect jwt header" do
    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer incorrect.jwt")
      |> AuthPlug.call(@opts)

    # redirect when auth fails
    assert conn.status == 302
  end

  test "Fail when authorization header token is invalid" do
    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer this.will.fail")
      |> AuthPlug.call(@opts)

    # redirect when auth fails
    assert conn.status == 302
  end

  test "Conn.assign decoded (the verified JWT)" do
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = Token.generate_jwt!(data)

    conn =
      conn(:get, "/admin")
      |> assign(:jwt, jwt)
      |> AuthPlug.call(%{})

    assert conn.assigns.person.email == "alex@dwyl.com"
  end

  test "get_session(conn, :jwt)" do
    data = %{email: "alice@dwyl.com", name: "Alice"}
    jwt = Token.generate_jwt!(data)

    conn =
      conn(:get, "/admin")
      |> AuthPlug.setup_session()
      |> put_session(:jwt, jwt)
      |> AuthPlug.call(@opts)

    token = get_session(conn, :jwt)
    {:ok, decoded} = AuthPlug.Token.verify_jwt(token)
    assert Map.get(decoded, "email") == "alice@dwyl.com"
  end

  test "Plug assigns person=jwt to conn with valid jwt" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_jwt!(data)

    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> AuthPlug.call(%{})

    token = conn.assigns.jwt
    person = AuthPlug.Token.verify_jwt!(token)

    assert person["email"] == "person@dwyl.com"
  end

  test "Extract JWT from URL" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_jwt!(data)

    conn =
      conn(:get, "/admin?jwt=" <> jwt)
      |> AuthPlug.setup_session()
      |> put_session(:jwt, nil)
      |> AuthPlug.call(%{})

    assert conn.assigns.person.email == "person@dwyl.com"
  end

  test "create_session_mock/2" do
    claims = %{email: "person@dwyl.com", id: 1}
    conn =
      conn(:get, "/")
      |> AuthPlug.create_jwt_session(claims)

    assert conn.assigns.person == claims
  end

end
