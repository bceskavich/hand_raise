defmodule HandRaiseWeb.LobbyChannel do
  use Phoenix.Channel
  alias HandRaise.Presence

  def join("room:lobby", _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    Presence.track(socket, "users", %{id: socket.assigns[:current_user], is_hand_raised: false})
    {:noreply, socket}
  end

  # TODO: private rooms
  # def join("room:" <> _private_room_id, _params, _socket) do
  #   {:error, %{reason: "Unauthorized"}}
  # end

  def handle_in("user_raise_changed", body, socket) do
    Presence.update(socket, "users", fn state ->
      %{state | is_hand_raised: body["is_hand_raised"]}
    end)
    {:noreply, socket}
  end
end
