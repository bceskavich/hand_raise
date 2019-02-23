defmodule HandRaiseWeb.SessionChannelTest do
  use HandRaiseWeb.ChannelCase

  alias Ecto.UUID
  alias HandRaiseWeb.{AppSocket, SessionChannel}
  alias HandRaise.SessionServer.{Session, User}

  setup do
    with {:ok, pid} <- Session.start(),
         %Session{id: sid} <- Session.get_state(pid)
    do
      {:ok, _, socket} =
        socket(AppSocket, "socket_id", %{user_id: UUID.generate()})
        |> subscribe_and_join(SessionChannel, "session:" <> sid)

      {:ok, socket: socket}
    end
  end

  test "set_user push event", %{socket: socket} do
    ref = push(socket, "set_user", %{"name" => "Jane Doe"})

    assert_reply ref, :ok
    assert_broadcast "state_change", %Session{users: [%User{name: "Jane Doe"}]}
  end

  test "toggle_raised push event", %{socket: socket} do
    push(socket, "set_user", %{"name" => "Jane Doe"})
    push(socket, "toggle_raised", %{"user_id" => socket.assigns[:user_id]})

    assert_broadcast "state_change", %Session{users: [%User{is_raised: true}]}
  end
end
