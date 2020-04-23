defmodule AuthPlugHelpersTest do
  use ExUnit.Case, async: true
  import AuthPlug.Helpers

  test "get_baseurl_from_conn(conn) detects the URL based on conn.host" do
    conn = %{
      host: "localhost",
      port: 4000
    }

    assert get_baseurl_from_conn(conn) == "http://localhost:4000"
  end

  test "get_baseurl_from_conn(conn) detects the URL for production" do
    conn = %{
      host: "dwyl.com",
      port: 80
    }

    assert get_baseurl_from_conn(conn) == "https://dwyl.com"
  end
end
