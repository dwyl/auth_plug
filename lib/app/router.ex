defmodule AuthPlug.Router do
  import Plug.Conn
  use Plug.Router
  use Plug.ErrorHandler
  # alias App.Plug.VerifyRequest
  @valid_secret String.duplicate("abcdef0123456789", 8)

  plug :put_secret_key_base
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  # plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  def put_secret_key_base(conn, _) do
    put_in(conn.secret_key_base, System.get_env("SECRET_KEY_BASE"))
  end
  # plug :fetch_session

  get "/" do
    opts = Plug.Session.init(store: :cookie, key: "_plugger",
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      secret: @valid_secret, signing_salt: "pWRHq+nw")
    conn = Plug.Session.call(conn, opts)
    conn = fetch_session(conn)
    conn = put_session(conn, :foo, "bar")

    foo = get_session(conn, :foo)
    send_resp(conn, 200, "Hello Elixir auth_plug!" <> foo)
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end
end
