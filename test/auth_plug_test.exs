defmodule AuthPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias AuthPlug.Token
  @url "https://dwylauth.herokuapp.com"
  @opts AuthPlug.init(%{auth_url: @url})

  test "Plug init function doesn't change params" do
    assert AuthPlug.init(%{}) == %{}
  end

  describe "test admin endpoint" do
    setup %{endpoint: endpoint} do
      test_conn =
        conn(:get, endpoint)
        |> init_test_session(%{})

      {:ok, conn: test_conn}
    end

    @tag endpoint: "/admin"
    test "Plug return 401 when no Authorization Header", %{conn: conn} do
      # conn = AuthPlug.call(conn(:get, "/admin"), @opts)
      # fetch_session(conn)
      # redirect when auth fails
      conn = AuthPlug.call(conn, @opts)
      assert conn.status == 302
    end

    @tag endpoint: "/admin"
    test "Plug return 401 wiht incorrect jwt header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer incorrect.jwt")
        |> AuthPlug.call(@opts)

      # redirect when auth fails
      assert conn.status == 302
    end

    @tag endpoint: "/admin"
    test "Fail when authorization header token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer this.will.fail")
        |> AuthPlug.call(@opts)

      # redirect when auth fails
      assert conn.status == 302
    end

    @tag endpoint: "/admin"
    test "Conn.assign decoded (the verified JWT)", %{conn: conn} do
      data = %{email: "alex@dwyl.com", name: "Alex"}
      jwt = Token.generate_jwt!(data)

      conn =
        conn
        |> assign(:jwt, jwt)
        |> AuthPlug.call(%{})

      assert conn.assigns.person.email == "alex@dwyl.com"
    end

    @tag endpoint: "/admin"
    test "get_session(conn, :jwt)", %{conn: conn} do
      data = %{email: "alice@dwyl.com", name: "Alice"}
      jwt = Token.generate_jwt!(data)

      conn =
        conn
        |> put_session(:jwt, jwt)
        |> AuthPlug.call(@opts)

      token = get_session(conn, :jwt)
      {:ok, decoded} = AuthPlug.Token.verify_jwt(token)
      assert Map.get(decoded, "email") == "alice@dwyl.com"
    end

    @tag endpoint: "/admin"
    test "Plug assigns person=jwt to conn with valid jwt", %{conn: conn} do
      data = %{email: "person@dwyl.com", session: 1}
      jwt = Token.generate_jwt!(data)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> AuthPlug.call(%{})

      token = conn.assigns.jwt
      person = AuthPlug.Token.verify_jwt!(token)

      assert person["email"] == "person@dwyl.com"
    end

    @tag endpoint: "/"
    test "create_session_mock/2", %{conn: conn} do
      claims = %{email: "person@dwyl.com", id: 1}

      conn =
        conn
        |> AuthPlug.create_jwt_session(claims)

      assert conn.assigns.person == claims
    end
  end

  test "Extract JWT from URL" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_jwt!(data)

    conn =
      conn(:get, "/admin?jwt=" <> jwt)
      |> init_test_session(%{})
      |> put_session(:jwt, nil)
      |> AuthPlug.call(%{})

    assert conn.assigns.person.email == "person@dwyl.com"
  end

  describe "Test logout/1" do

    setup %{endpoint: endpoint} do
      test_conn =
        conn(:get, endpoint)
        |> init_test_session(%{})

      {:ok, conn: test_conn}
    end

    @tag endpoint: "/admin"
    test "logout", %{conn: conn} do
      data = %{email: "alice@dwyl.com", name: "Alice"}
      jwt = AuthPlug.Token.generate_jwt!(data)

      conn =
        conn
        |> put_session(:jwt, jwt)
        |> AuthPlug.call(@opts)


      token = get_session(conn, :jwt)
      {:ok, decoded} = AuthPlug.Token.verify_jwt(token)
      assert Map.get(decoded, "email") == "alice@dwyl.com"

      # logout:
      conn_logged_out = AuthPlug.logout(conn)

      # should no longer be logged in:
      assert conn_logged_out.assigns == %{jwt: "", person: %{}}

      # attempt to access "/admin" endpoint
      conn_end =
        conn_logged_out
        |> AuthPlug.call(@opts)

      # should redirect as no longer authenticated/authorized:
      assert conn_end.request_path == "/admin"
      assert conn_end.status == 302
    end
  end
end
