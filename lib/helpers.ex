defmodule AuthPlug.Helpers do

  @doc """
  `get_baseurl_from_conn/1` derives the base URL from the conn struct
  """
  @spec get_baseurl_from_conn(Map) :: String.t
  def get_baseurl_from_conn(%{host: h, port: p}) when h == "localhost" do
    "http://#{h}:#{p}"
  end

  def get_baseurl_from_conn(%{host: h}) do
     "https://#{h}"
  end

end
