defmodule AuthPlug.Router do
  use Plug.Router
  # use Plug.ErrorHandler

  # plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug AuthPlug, paths: ["/admin"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello Elixir Plug!")
  end

  get "/admin" do
    send_resp(conn, 200, "Totes Admin")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end

  # def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
  #   IO.inspect(kind, label: :kind)
  #   IO.inspect(reason, label: :reason)
  #   IO.inspect(stack, label: :stack)
  #   send_resp(conn, conn.status, "unauthorized")
  # end
end
