defmodule AuthPlug.Token do
  @moduledoc """
  Token module to create and validate jwt.
  see https://hexdocs.pm/joken/configuration.html#module-approach

  """
  use Joken.Config
  @secret System.get_env("SECRET_KEY_BASE")
  @signer Joken.Signer.create("HS256", @secret)

  @impl true
  def token_config do
    # ~ 1 year in seconds
    default_claims(default_exp: 31_537_000)
  end

  @doc """
  `generate_jwt!/1` invokes `Joken.generate_and_sign/3`
  claims are the data to be signed.
  """
  def generate_jwt!(claims) do
    {:ok, token, _claims} =
      token_config()
      |> Joken.generate_and_sign(claims, @signer)

    token
  end

  @doc """
  `verify_jwt/1` verifies the given JWT and returns {:ok, claims}
  where the claims are the original data that were signed.
  """
  def verify_jwt(token) do
    token_config()
    |> Joken.verify_and_validate(token, @signer)
  end

  @doc """
  `verify_jwt!/1` verifies the given JWT and returns claims
  where the claims are the original data that were signed.
  """
  def verify_jwt!(token) do
    {:ok, claims} =
      token_config()
      |> Joken.verify_and_validate(token, @signer)

    claims
  end
end
