defmodule AuthPlug.Token do
  @moduledoc """
  Token module to create and validate jwt.
  see https://hexdocs.pm/joken/configuration.html#module-approach
  """
  use Joken.Config

  @doc """
  `api_key/0` retrieves the API_KEY from environment variable.
   API keys are a single environment variable which is comprised of two parts.
   client_id/client_secret such that splitting on the "/" (forward slash)
   gives us the `client_id` and `client_secret`
   example:
   2cfxNaWUwJBq1F4nPndoEHZJ5YCCNq9JDNAAR/2cfxNadrhMZk3iaT1L5k6Wt67c9ScbGNPz8Bw
   see: https://github.com/dwyl/auth/issues/42#issuecomment-620247243
  """
  def api_key do
    if not is_nil(System.get_env("DWYL_API_KEY")),
    do: System.get_env("DWYL_API_KEY"),
    else: System.get_env("AUTH_API_KEY")
  end

  @doc """
  `client_id/0` returns the `client_id` (the first part of the AUTH_API_KEY)
  """
  def client_id do
    List.first(String.split(api_key(), "/"))
  end

  @doc """
  `client_id/0` returns the `client_secret` (the last part of the AUTH_API_KEY)
  """
  def client_secret do
    List.last(String.split(api_key(), "/"))
  end

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
    generate_jwt!(claims, client_secret())
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
  def verify_jwt(nil) do
    # Fail fast on a nil token
    {:error, "No jwt provided"}
  end

  def verify_jwt(token) do
    verify_jwt(token, client_secret())
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
    verify_jwt!(token, client_secret())
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
