defmodule AuthPlug.Router do
  use Plug.Router

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
end
