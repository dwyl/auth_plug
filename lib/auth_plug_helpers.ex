defmodule AuthPlug.Helpers do
  @doc """
  `get_baseurl_from_conn/1` derives the base URL from the conn struct
  e.g: http://localhost:4000 or https://app.dwyl.com
  """

  require Logger

  @spec get_baseurl_from_conn(Map) :: String.t()
  def get_baseurl_from_conn(%{host: h, port: p}) when h == "localhost" do
    "http://#{h}:#{p}"
  end

  def get_baseurl_from_conn(%{host: h}) do
    "https://#{h}"
  end

  @doc """
  `strip_struct_metadata/1` removes the Ecto Struct metadata from a struct.
  This is essential before attempting to create a JWT as `Jason.encode/2`
  chokes on any invalid data. See: github.com/dwyl/auth_plug/issues/16
  """
  def strip_struct_metadata(struct) do
    struct
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)
    # association
    |> Map.delete(:statuses)
    # association
    |> Map.delete(:login_logs)
    # binary
    |> Map.delete(:email_hash)
  end

  @doc """
  `check_environment_vars/0` displays a friendly error message
  if the AUTH_API_KEY environment variable is not defined.
  """
  def check_environment_vars do
    key = AuthPlug.Token.api_key()
    # ignoring this because :api_key is hard-coded in config/test.exs
    # coveralls-ignore-start
    if is_nil(key) do
      Logger.error("No AUTH_API_KEY set, find out how at: https://git.io/JJ6sS")
    end

    # coveralls-ignore-stop
    key
  end
end
