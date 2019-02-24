defmodule HandRaiseWeb.Router do
  use HandRaiseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    # TODO: maybe move into a controller?
    plug :create_session_user
    plug :create_session_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HandRaiseWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/:id", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HandRaiseWeb do
  #   pipe_through :api
  # end

  defp create_session_user(conn, _) do
    assign(conn, :session_user, Ecto.UUID.generate())
  end

  defp create_session_user_token(conn, _) do
    if user = conn.assigns[:session_user] do
      token = Phoenix.Token.sign(conn, "socket_user", user)
      assign(conn, :session_user_token, token)
    else
      conn
    end
  end
end
