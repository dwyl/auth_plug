defmodule AuthPlugOptionalTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias AuthPlug.Token
  @opts AuthPlugOptional.init(%{})

  test "init/1 returns options unmodified" do
    assert AuthPlugOptional.init(%{}) == %{}
  end

  describe "test admin endpoint" do
    setup %{endpoint: endpoint} do
      test_conn =
        conn(:get, endpoint)
        |> init_test_session(%{})

      {:ok, conn: test_conn}
    end

    @tag endpoint: "/optional"
    test "No Error if JWT is not defined", %{conn: conn} do
      conn = AuthPlugOptional.call(conn, @opts)
      # AuthPlugOptional does NOT set the HTTP status code:
      assert conn.status == nil
      # nothing is set on conn.assigns
      assert conn.assigns == %{loggedin: false}
    end

    @tag endpoint: "/optional"
    test "Conn.assign.person (the verified JWT)", %{conn: conn} do
      data = %{email: "alex@dwyl.com", name: "Alex"}
      jwt = Token.generate_jwt!(data)

      conn =
        conn
        |> assign(:jwt, jwt)
        |> AuthPlugOptional.call(%{})

      assert conn.assigns.person.email == "alex@dwyl.com"
    end
  end
end
