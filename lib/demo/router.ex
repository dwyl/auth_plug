defmodule AuthPlug.Router do
  # this is a basic router example so we can test the plug on localhost
  #  if you want to run it, uncomment the line that starts with "mod:" in mix.exs
  #  then run "mix run --no-halt"
  import Plug.Conn
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(AuthPlugOptional, %{})
  plug(AuthPlug)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello Elixir auth_plug!")
  end

  get "/admin" do
    person = conn.assigns.person

    send_resp(
      conn,
      200,
      "Hello " <>
        person.name <>
        "! " <>
        "You are logged in with email: " <> person.email
    )
  end

  get "/optional" do
    person = conn.assigns.person
    msg = if is_nil(person.name), do: "Hello Stranger!", else: "Hello #{person.givenName}!"

    send_resp(
      conn,
      200,
      "Hello " <> msg
    )
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
