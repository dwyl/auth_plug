defmodule AuthPlugTokenTest do
  use ExUnit.Case, async: true
  import AuthPlug.Token

  test "api_key/0 with AUTH_API_KEY" do
    assert api_key() == System.get_env("AUTH_API_KEY")
  end

  test "generate_jwt!/2 creates a JWT with the given data and secret" do
    secret = "secretcanbeanystringyouwant"
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = generate_jwt!(data, secret)
    assert Enum.count(String.split(jwt, ".")) == 3

    decoded = verify_jwt!(jwt, secret)
    assert data.email == Map.get(decoded, "email")
  end

  test "verify_jwt/2 verifies a JWT with the given secret" do
    secret = "secretcanbeanystringyouwant"
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = generate_jwt!(data, secret)

    {:ok, decoded} = verify_jwt(jwt, secret)
    assert data.email == Map.get(decoded, "email")
  end

  test "api_key/0 with DWYL_API_KEY" do
    System.put_env("DWYL_API_KEY", System.get_env("AUTH_API_KEY"))
    assert api_key() == System.get_env("AUTH_API_KEY")
    # System.put_env("DWYL_API_KEY", nil)
  end
end
