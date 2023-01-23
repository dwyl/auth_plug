defmodule AuthPlugOptional do
  @moduledoc """
  `AuthPlugOptional` handles any route where authentication is optional
  e.g. if you're building a CMS where content is public
  but seeing comments requires auth, the same page can show different
  content depending on if the person has logged in or not.
  Please see `README.md` for for optional auth usage.
  """
  require Logger
  import Plug.Conn, only: [assign: 3]

  @doc """
  `init/1` returns options unmodified
  """
  def init(options), do: options

  @doc """
  `call/2` is invoked to handle each HTTP request which `auth_plug` protects.
  If the `conn` contains a valid JWT in Authentication Headers, URL or Cookie,
  then continue to the optionally protected route with the conn.assigns.person
  defined so that the controller can determine what content to show the person.
  NOTE: this plug does NOT set the HTTP Status on a request, that is left to you.
  """
  def call(conn, _options) do
    jwt = AuthPlug.Token.get_jwt(conn)

    case AuthPlug.Token.verify_jwt(jwt) do
      # Valid JWT, assign the session data and return conn:
      {:ok, values} ->
        AuthPlug.Token.put_current_token(conn, jwt, values)

      # Don't do anything as there is no valid JWT and Auth is Optional
      {:error, _reason} ->
        conn
        # github.com/dwyl/auth_plug/issues/83
        |> assign(:loggedin, false)
    end
  end
end
