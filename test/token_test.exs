defmodule AuthPlugTokenTest do
  use ExUnit.Case, async: true
  import AuthPlug.Token

  test "generate_jwt!/2 creates a JWT with the given data and secret" do
    secret = "secretcanbeanystringyouwant"
    data = %{email: "alex@dwyl.com", name: "Alex"}
    jwt = generate_jwt!(data, secret)
    assert Enum.count(String.split(jwt, ".")) == 3

    decoded = verify_jwt!(jwt, secret)
    assert data.email == Map.get(decoded, "email")
  end
end
