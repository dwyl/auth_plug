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

  test "check_environment_vars raises error if AUTH_API_KEY is not set" do
    key = System.get_env("AUTH_API_KEY")
    # delete the environment variable:
    System.delete_env("AUTH_API_KEY")

    # confirm that the correct error is raised:
    assert_raise RuntimeError,
                 "No AUTH_API_KEY set, find out how at: https://git.io/JJ6sS",
                 fn ->
                   check_environment_vars()
                 end

    # see: til.hashrocket.com/posts/0b1f205523-assert-an-exception-is-raised

    # restore the environment variable:
    System.put_env("AUTH_API_KEY", key)
  end
end
