defmodule HandRaiseWeb.LobbyChannel do
  use Phoenix.Channel

  alias HandRaise.SessionServer.Session

  def join("room:lobby", _, socket) do
    {:ok, socket}
  end

  def handle_in("create_session", _, socket) do
    with {:ok, pid} <- Session.start(),
         %Session{id: sid} <- Session.get_state(pid)
    do
      {:reply, {:ok, %{session_id: sid}}, socket}
    end
  end
end
