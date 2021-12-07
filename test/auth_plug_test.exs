defmodule AuthPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias AuthPlug.Token

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
      # redirect when auth fails
      conn = AuthPlug.call(conn, %{})
      assert conn.status == 302
    end

    @tag endpoint: "/admin"
    test "Plug return 401 wiht incorrect jwt header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer incorrect.jwt")
        |> AuthPlug.call(%{})

      # redirect when auth fails
      assert conn.status == 302
    end

    @tag endpoint: "/admin"
    test "Fail when authorization header token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer this.will.fail")
        |> AuthPlug.call(%{})

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
        |> AuthPlug.call(%{})

      token = get_session(conn, :jwt)
      {:ok, decoded} = AuthPlug.Token.verify_jwt(token)
      assert Map.get(decoded, "email") == "alice@dwyl.com"
    end

    @tag endpoint: "/admin"
    test "Plug assigns person=jwt to conn with valid jwt", %{conn: conn} do
      data = %{email: "person@dwyl.com", sid: 1}
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

    @tag endpoint: "/logout"
    test "logout/1" do
      data = %{email: "alice@dwyl.com", name: "Alice", id: 1, app_id: 1, sid: 123}
      jwt = AuthPlug.Token.generate_jwt!(data)

      # Call the Plug with "/logout" path expect logout/1 to be called.
      conn =
        conn(:get, "/logout?jwt=#{jwt}")
        |> init_test_session(%{})
        # |> put_session(:jwt, jwt)
        |> AuthPlug.Token.create_jwt_session(data)
        |> AuthPlug.logout()

      assert conn.status == 200
      assert conn.assigns == %{state: "logout"}
    end

    @tag endpoint: "/logout"
    test "end_session/1 should end the session on auth_url/end_session", %{conn: conn} do
      data = %{email: "alexa@dwyl.com", name: "Alice", id: 1, app_id: 1, sid: 234}
      jwt = AuthPlug.Token.generate_jwt!(data)

      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:jwt, jwt)
        |> AuthPlug.end_session()

      assert conn.status == 200
      assert conn.resp_body == "session ended"
    end

    @tag endpoint: "/"
    test "get_auth_url", %{conn: conn} do
      conn = AuthPlug.call(conn, %{})
      auth_url = "https://dwylauth.herokuapp.com"
      url1 = "#{auth_url}?referer=https://www.example.com/&auth_client_id="
      url2 = "#{auth_url}?referer=https://www.example.com/redirect_here&auth_client_id="

      assert AuthPlug.get_auth_url(conn) =~ url1
      assert AuthPlug.get_auth_url(conn, "/redirect_here") =~ url2
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
end
