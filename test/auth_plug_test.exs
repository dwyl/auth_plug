defmodule AuthPlugTest do
  use ExUnit.Case
  use Plug.Test
  alias AuthPlug.Token
  @signer Joken.Signer.create("HS256", "secret")

  test "Plug init function doesn't change params" do
    assert AuthPlug.init(%{}) == %{}

  end

  test "Plug return 401 wiht not Authorization Header" do
    conn = AuthPlug.call(conn("/admin", ""), %{})

    assert conn.status == 401
  end

  test "Plug return 401 wiht incorrect jwt header" do
    conn = conn("/admin", "")
           |> put_req_header("authorization", "Bearer incorrect.jwt")
           |> AuthPlug.call(%{})

    assert conn.status == 401
  end

  test "Fail when authorization header token is invalid" do
    conn = conn("/admin", "")
           |> put_req_header("authorization", "Bearer this.will.fail")
           |> AuthPlug.call(%{})

    assert conn.status == 401
  end

  test "Plug assigns claims to conn with valid jwt" do
    data = %{email: "person@dwyl.com", session: 1 }
    jwt = Token.generate_and_sign!(data, @signer)
    conn = conn("/admin", "")
           |> put_req_header("authorization", "Bearer #{jwt}")
           |> AuthPlug.call(%{})

    assert conn.assigns.claims.email == "person@dwyl.com"
  end
end
