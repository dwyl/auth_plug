defmodule AuthPlug.Token do
  @moduledoc """
  Token module to create and validate jwt.
  see https://hexdocs.pm/joken/configuration.html#module-approach
  """
  use Joken.Config
  @secret System.get_env("SECRET_KEY_BASE")

  @doc """
  `create_signer/1` creates a signer for the given `secret` key.
  It uses the HS256 (HMAC with SHA-256) to generate the signature.
  if you're wondering what "HS256" is, read:
  community.auth0.com/t/jwt-signing-algorithms-rs256-vs-hs256/7720
  """
  def create_signer(secret) do
    Joken.Signer.create("HS256", secret)
  end

  @impl true
  def token_config do
    # ~ 1 year in seconds
    default_claims(default_exp: 31_537_000)
  end

  @doc """
  `generate_jwt!/1` invokes `Joken.generate_and_sign/3`
  claims are the data to be signed.
  Throws an error if anyting in the claims is invalid.
  """
  def generate_jwt!(claims) do
    generate_jwt!(claims, @secret)
  end

  @doc """
  `generate_jwt!/2` invokes `Joken.generate_and_sign/3`
  `claims` are the data to be signed and `secret` is the secret key.
  """
  def generate_jwt!(claims, secret) do
    signer = create_signer(secret)
    {:ok, token, _claims} =
      token_config()
      |> Joken.generate_and_sign(claims, signer)

    token
  end

  @doc """
  `verify_jwt/1` verifies the given JWT and returns {:ok, claims}
  where the claims are the original data that were signed.
  """
  def verify_jwt(token) do
    verify_jwt(token, @secret)
  end

  @doc """
  `verify_jwt/2` verifies the given JWT and secret.
  Returns {:ok, claims} where the claims are the original data that were signed.
  """
  def verify_jwt(token, secret) do
    signer = create_signer(secret)
    token_config()
    |> Joken.verify_and_validate(token, signer)
  end

  @doc """
  `verify_jwt!/1` verifies the given JWT and returns claims
  where the claims are the original data that were signed.
  """
  def verify_jwt!(token) do
    verify_jwt!(token, @secret)
  end

  @doc """
  `verify_jwt!/2` verifies the given JWT and returns claims
  where the `token` is the JWT that was signed `secret` is the secret key.
  Returns `claims` the original claims contained in the JWT.
  """
  def verify_jwt!(token, secret) do
    signer = create_signer(secret)
    {:ok, claims} =
      token_config()
      |> Joken.verify_and_validate(token, signer)

    claims
  end

end
