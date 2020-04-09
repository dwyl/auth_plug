defmodule AuthPlugTest do
  use ExUnit.Case
  use Plug.Test
  # doctest AuthPlug
  @signer Joken.Signer.create("HS256", "secret")


  test "greets the world" do
    assert true == true # AuthPlug.hello() == :world
  end
# end

# defmodule AuthPlugTest do
  # use AuthMvpWeb.ConnCase

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

  test "Plug assigns claims to conn with valid jwt" do
    data = %{email: "person@dwyl.com", session: 1 }
    jwt = AuthPlug.Token.generate_and_sign!(data, @signer)
    conn = conn("/admin", "")
           |> put_req_header("authorization", "Bearer #{jwt}")
           |> AuthPlug.call(%{})

    assert conn.assigns.claims.email == "person@dwyl.com"
  end
end
