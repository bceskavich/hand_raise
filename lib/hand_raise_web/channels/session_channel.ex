defmodule HandRaiseWeb.SessionChannel do
  use Phoenix.Channel

  alias HandRaise.SessionServer.Session

  def join("session:" <> session_id, _, socket) do
    name = Session.get_name(session_id)

    case Session.is_alive?(name) do
      true -> {:ok, assign(socket, :session, name)}
      false -> {:error, %{reason: "Session terminated"}}
    end
  end

  def handle_in("set_user", %{"name" => name}, socket) do
    socket.assigns[:session]
    |> Session.join(id: socket.assigns[:user_id], name: name)

    state_change(socket)
    {:reply, :ok, socket}
  end

  def handle_in("toggle_raised", %{"user_id" => uid}, socket) do
    socket.assigns[:session]
    |> Session.toggle_raise(uid)

    state_change(socket)
    {:noreply, socket}
  end

  def terminate({:shutdown, :left}, socket), do: leave(socket)
  def terminate({:shutdown, :closed}, socket), do: leave(socket)

  defp leave(socket) do
    socket.assigns[:session]
    |> Session.leave(socket.assigns[:user_id])

    state_change(socket)
  end

  defp state_change(socket) do
    state =
      socket.assigns[:session]
      |> Session.get_state()

    broadcast(socket, "state_change", state)
  end
end
