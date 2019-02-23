defmodule HandRaiseWeb.LobbyChannelTest do
  use HandRaiseWeb.ChannelCase

  alias Ecto.UUID
  alias HandRaiseWeb.{AppSocket, LobbyChannel}
  alias HandRaise.SessionServer.Session

  setup do
    {:ok, _, socket} =
      socket(AppSocket, "socket_id", %{user_id: UUID.generate()})
      |> subscribe_and_join(LobbyChannel, "room:lobby")

    {:ok, socket: socket}
  end

  test "create_session push event", %{socket: socket} do
    ref = push(socket, "create_session", %{})

    assert_reply ref, :ok, %{session_id: sid}

    state =
      sid
      |> Session.get_name()
      |> Session.get_state()

    assert state == %Session{id: sid, users: []}
  end
end
