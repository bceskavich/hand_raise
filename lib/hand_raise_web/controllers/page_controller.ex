defmodule HandRaiseWeb.PageController do
  use HandRaiseWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
