defmodule AuthPlug.Router do
  import Plug.Conn
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger, log: :debug)
  plug(AuthPlug, paths: ["/admin"])
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello Elixir auth_plug!")
  end

  get "/admin" do
    foo = get_session(conn, :foo)
    send_resp(conn, 200, "Hello Admin " <> foo <> "!")
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
