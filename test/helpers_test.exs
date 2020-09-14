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

  test "check_environment_vars/0 without AUTH_API_KEY throws" do
    auth_api_key = System.get_env("AUTH_API_KEY")
    # set the AUTH_API_KEY to empty string to rais the error:
    System.put_env("AUTH_API_KEY", "")

    try do
      check_environment_vars()
    rescue
      e in RuntimeError ->
        assert e.message ==
          "No AUTH_API_KEY set, find out how at: https://git.io/JJ6sS"
    end

    # reset the AUTH_API_KEY to the original value:
    System.put_env("AUTH_API_KEY", auth_api_key)
  end
end
