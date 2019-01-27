defmodule HandRaise.SessionServer.SessionTest do
  use HandRaise.DataCase

  alias HandRaise.SessionServer.{Session, User}

  describe "#start/0" do
    test "It starts an empty Session managed by HandRaise.SessionServer.DynamicSupervisor" do
      {:ok, _} = Session.start()
    end
  end

  describe "#terminate/1" do
    test "It terminates a Session by HandRaise.SessionServer.DynamicSupervisor" do
      {:ok, pid} = Session.start()
      :ok = Session.terminate(pid)
    end
  end

  describe "#join/2" do
    setup [:setup_session]

    test "A new user can join the Session", %{session: session} do
      %User{} = user = Session.join(session, "Jane Doe")
      assert user.name == "Jane Doe"
      assert user.is_raised == false
    end
  end

  describe "#toggle_raise/2" do
    setup [:setup_session]

    test "It can toggle the `is_raised` flag for a user in the Session", %{session: session} do
      %User{id: uid, is_raised: is_raised} = Session.join(session, "Jane Doe")
      assert is_raised == false

      :ok = Session.toggle_raise(session, uid)
      user = Session.get_user(session, uid)
      assert user.is_raised
    end

    test "It will simply ignore a toggle for a user that does not exist", %{session: session} do
      :ok = Session.toggle_raise(session, "does-not-exist")
    end
  end

  describe "#leave/2" do
    setup [:setup_session]

    test "A user can leave the Session", %{session: session} do
      %User{id: uid} = Session.join(session, "Jane Doe")

      :ok = Session.leave(session, uid)
      assert Session.get_user(session, uid) == nil
    end

    test "It will simply ignore a leave call for a user that does not exist", %{session: session} do
      :ok = Session.leave(session, "does-not-exist")
    end
  end

  describe "#get_state/1" do
    setup [:setup_session]

    test "Returns the current Session state", %{session: session} do
      user1 = Session.join(session, "Jane Doe")
      user2 = Session.join(session, "John Doe")
      Session.toggle_raise(session, user1.id)

      state = Session.get_state(session)
      assert state.id != nil
      assert state.users == [
        Session.get_user(session, user2.id),
        Session.get_user(session, user1.id)
      ]
    end
  end

  def setup_session(_) do
    {:ok, session} = Session.start()
    [session: session]
  end
end
