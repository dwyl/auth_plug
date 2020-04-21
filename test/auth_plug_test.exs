defmodule AuthPlugTest do
  use ExUnit.Case
  use Plug.Test
  alias AuthPlug.Token
  @secret System.get_env("SECRET_KEY_BASE")
  @signer Joken.Signer.create("HS256", @secret)
  @opts AuthPlug.init(%{auth_url: "https://elixir-auth-google-demo.herokuapp.com"})
  # IO.inspect(@opts, label: "@opts:8")

  test "Plug init function doesn't change params" do
    assert AuthPlug.init(%{}) == %{}
  end

  test "Plug return 401 wiht not Authorization Header" do
    conn = AuthPlug.call(conn(:get, "/admin"), @opts)

    assert conn.status == 301 # redirect when auth fails
  end

  test "Plug return 401 wiht incorrect jwt header" do
    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer incorrect.jwt")
      |> AuthPlug.call(@opts)

    assert conn.status == 301 # redirect when auth fails
  end

  test "Fail when authorization header token is invalid" do
    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer this.will.fail")
      |> AuthPlug.call(@opts)

    assert conn.status == 301 # redirect when auth fails
  end

  test "Conn.assign decoded (the verified JWT)" do
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = Token.generate_and_sign!(data, @signer)

    conn = conn(:get, "/admin")
      |> assign(:person, jwt)
      # |> IO.inspect(label: "assigned")
      |> AuthPlug.call(%{})
      # |> IO.inspect(label: "called")

    assert conn.assigns.decoded.email == "alex@dwyl.com"
  end

  test "get_session(conn, :person)"do
    data = %{email: "alice@dwyl.com", name: "Alice"}
    jwt = Token.generate_and_sign!(data, @signer)

    conn = conn(:get, "/admin")
      |> AuthPlug.setup_session()
      |> put_session(:person, jwt)
      |> AuthPlug.call(@opts)

    token = get_session(conn, :person)
    {:ok, decoded} = AuthPlug.Token.verify_and_validate(token, @signer)
    assert Map.get(decoded, "email") == "alice@dwyl.com"

  end

  test "Plug assigns person=jwt to conn with valid jwt" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_and_sign!(data, @signer)

    conn =
      conn(:get, "/admin")
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> AuthPlug.call(%{})

    token = conn.assigns.person
    {:ok, person} = AuthPlug.Token.verify_and_validate(token, @signer)
    assert person["email"] == "person@dwyl.com"
  end

  test "Extract JWT from URL" do
    data = %{email: "person@dwyl.com", session: 1}
    jwt = Token.generate_and_sign!(data, @signer)

    conn = conn(:get, "/admin?jwt=" <> jwt)
      |> AuthPlug.setup_session()
      |> put_session(:person, nil)
      |> AuthPlug.call(%{})

    assert conn.assigns.decoded.email == "person@dwyl.com"
  end
end
