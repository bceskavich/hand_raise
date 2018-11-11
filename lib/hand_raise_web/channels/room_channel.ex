defmodule HandRaiseWeb.RoomChannel do
  use Phoenix.Channel
  alias HandRaise.Presence

  def join("room:lobby", _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_list", Presence.list(socket))
    Presence.track(socket, "users", %{user: socket.assigns[:current_user]})
    broadcast!(socket, "user_joined", %{user: socket.assigns[:current_user]})
    {:noreply, socket}
  end

  def terminate({:shutdown, :closed}, socket) do
    broadcast!(socket, "user_left", %{user: socket.assigns[:current_user]})
  end
  def terminate({:shutdown, :left}, socket) do
    broadcast!(socket, "user_left", %{user: socket.assigns[:current_user]})
  end

  # TODO: private rooms
  # def join("room:" <> _private_room_id, _params, _socket) do
  #   {:error, %{reason: "Unauthorized"}}
  # end

  def handle_in("user_hand_raised", body, socket) do
    broadcast!(socket, "user_hand_raised", body)
    {:noreply, socket}
  end

  def handle_in("user_hand_lowered", body, socket) do
    broadcast!(socket, "user_hand_lowered", body)
    {:noreply, socket}
  end
end
