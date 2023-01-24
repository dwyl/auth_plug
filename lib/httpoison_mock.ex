defmodule AuthPlug.HTTPoisonMock do
  @moduledoc """
  This is a TestDouble for HTTPoison which returns a predictable response.
  Please see: https://github.com/dwyl/elixir-auth-google/issues/35
  """

  @doc """
  post/2 using a dummy _url to test body decoding.
  """
  def post("wrong-auth-url", _body) do
    {:error, "no app there"}
  end

  def post("wrong-post-endpoint", _body) do
    {:ok, %{status_code: 404, body: Jason.encode!(%{message: "not found"})}}
  end

  def post(_url, _body) do
    {:ok, %{status_code: 200, body: Jason.encode!(%{message: "session ended"})}}
  end
end
