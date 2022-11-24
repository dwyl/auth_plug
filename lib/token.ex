defmodule AuthPlug.Token do
  @moduledoc """
  Token module to create and validate jwt.
  see https://hexdocs.pm/joken/configuration.html#module-approach
  """
  import Plug.Conn,
    only: [
      assign: 3,
      configure_session: 2,
      get_req_header: 2,
      get_session: 2,
      put_session: 3
    ]

  use Joken.Config

  @doc """
  `api_key/0` retrieves the API_KEY from environment variable.
   API keys are a single environment variable which is comprised of two parts.
   client_id/client_secret such that splitting on the "/" (forward slash)
   gives us the `client_id` and `client_secret`
   example:
   2cfxNaWUwJBq1F4nPndoEHZJ5YCCNq9JDNAAR/2cfxNadrhMZk3iaT1L5k6Wt67c9ScbGNPz8Bw/dwylauth.herokuapp.com
   see: https://github.com/dwyl/auth/issues/42#issuecomment-620247243
  """
  def api_key do
    Envar.get("AUTH_API_KEY", Application.fetch_env!(:auth_plug, :api_key))
  end

  @doc """
  This regex splits the 3 parts of the `AUTH_API_KEY` (id, secret and auth_url)
  e.g:
  - (.*) match any characters multiple time
  - \/ escapes the forwardslash /
  """
  def split_env() do
    Regex.run(~r/^(.*)\/(.*)\/(.*)$/, api_key())
  end

  @doc """
  `client_id/0` returns the `client_id` (the first part of the AUTH_API_KEY)
  """
  def client_id do
    [_all, id, _secret, _auth_url] = split_env()
    id
  end

  @doc """
  `client_secret/0` returns the `client_secret` (the middle part of the AUTH_API_KEY)
  """
  def client_secret do
    [_all, _id, secret, _auth_url] = split_env()
    secret
  end

  @doc """
  `auth_url/0` returns the `auth_url` (the last part of the AUTH_API_KEY)
  """
  def auth_url do
    [_all, _id, _secret, auth_url] = split_env()
    "https://" <> auth_url
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

  @doc """
  `get_jwt/1` extracts the JWT from HTTP Request headers, URL or Cookie.
  If no JWT is found, it returns nil.
  """
  def get_jwt(conn) do
    cond do
      # First Check for JWT in URL Query String.
      # We want a *new* session to supercede any expired session,
      #  so the check for JWT *before* anything else.
      conn.query_string =~ "jwt" ->
        query = URI.decode_query(conn.query_string)
        Map.get(query, "jwt")

      # Check for JWT in Headers:
      Enum.count(get_req_header(conn, "authorization")) > 0 ->
        conn.req_headers
        |> List.keyfind("authorization", 0, "")
        |> get_token_from_header()

      #  Check for Person in Plug.Conn.assigns
      not is_nil(conn.assigns[:jwt]) ->
        conn.assigns.jwt

      # Check for Session in Plug.Session:
      not is_nil(get_session(conn, :jwt)) ->
        get_session(conn, :jwt)

      # By default return nil so auth check fails
      true ->
        nil
    end
  end

  @doc """
  `create_session/2` takes a `conn`, claims and a JWT
  and creates the session using Phoenix Sessions
  and the JWT as the value so that it can be checked
  on each future request.
  Makes the decoded JWT available in conn.assigns.person
  which means it can be used in templates.
  """
  def create_session(conn, claims, jwt) do
    claims = AuthPlug.Helpers.strip_struct_metadata(claims)

    conn
    |> assign(:loggedin, true)
    |> assign(:person, claims)
    |> assign(:jwt, jwt)
    |> put_session(:jwt, jwt)
    |> configure_session(renew: true)
  end

  @doc """
  `put_current_token/3` takes a `conn`, JWT and values (decoded JWT)
  and creates the session using `create_session/2` defined above.
  """
  def put_current_token(conn, jwt, values) do
    # convert map of string to atom: stackoverflow.com/questions/31990134
    claims = for {k, v} <- values, into: %{}, do: {String.to_atom(k), v}
    # return the conn with the session
    create_session(conn, claims, jwt)
  end

  @doc """
  `create_jwt_session/2` recieves a `conn` (Plug.Conn) and `claims`
  e.g: `%{email: "person@dwyl.com", id: 1}`.
  Signs a JWT which gets attached to the session.
  This is super-useful in testing as we
  can simply invoke
  `create_jwt_session(conn, %{email: "al@ex.co", id: 1})`
  and continue the request pipeline with a valid session.
  """
  def create_jwt_session(conn, claims) do
    # delete %Auth.Person github.com/dwyl/auth_plug/issues/16
    jwt =
      claims
      |> AuthPlug.Helpers.strip_struct_metadata()
      |> AuthPlug.Token.generate_jwt!()

    AuthPlug.Token.create_session(conn, claims, jwt)
  end

  # check JWT format by counting number of "." is equal to 3
  # see https://en.wikipedia.org/wiki/JSON_Web_Token#Structure
  defp get_token_from_header({"authorization", value}) do
    token =
      value
      |> String.replace("Bearer", "")
      |> String.trim()

    jwt_valid_format =
      token
      |> String.split(".")
      |> Enum.count() == 3

    if jwt_valid_format, do: token, else: nil
  end
end
