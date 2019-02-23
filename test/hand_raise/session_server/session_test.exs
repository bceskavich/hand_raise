defmodule HandRaise.SessionServer.SessionTest do
  use HandRaise.DataCase

  alias Ecto.UUID
  alias HandRaise.SessionServer.{
    Session,
    SessionRegistry,
    User
  }

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

  describe "#get_name/1" do
    setup [:setup_session]

    test "It builds a name when provided with a PID", %{session: session} do
      {:via, Registry, {SessionRegistry, id}} = Session.get_name(session)

      state = Session.get_state(session)
      assert state.id == id
    end

    test "It builds a name when provided with a UUID" do
      id = Ecto.UUID.generate()
      name = Session.get_name(id)
      assert name == {:via, Registry, {SessionRegistry, id}}
    end

    test "It returns the name if provided", %{session: session} do
      name = Session.get_name(session)
      assert name == Session.get_name(name)
    end

    test "It can call to the Session with its Registry name", %{session: session} do
      name = Session.get_name(session)
      %Session{} = Session.get_state(name)
    end
  end

  describe "#join/2" do
    setup [:setup_session]

    test "A new user can join the Session", %{session: session} do
      with uid <- UUID.generate(),
           :ok <- Session.join(session, id: uid, name: "Jane Doe"),
           %Session{users: [user]} <- Session.get_state(session)
      do
        assert user.id == uid
        assert user.name == "Jane Doe"
        assert user.is_raised == false
      end
    end
  end

  describe "#toggle_raise/2" do
    setup [:setup_session]

    test "It can toggle the `is_raised` flag for a user in the Session", %{session: session} do
      with uid <- UUID.generate(),
           :ok <- Session.join(session, id: uid, name: "Jane Doe"),
           :ok <- Session.toggle_raise(session, uid),
           %Session{users: [user]} <- Session.get_state(session)
      do
        assert user.is_raised
      end
    end

    test "It will simply ignore a toggle for a user that does not exist", %{session: session} do
      :ok = Session.toggle_raise(session, "does-not-exist")
    end
  end

  describe "#leave/2" do
    setup [:setup_session]

    test "A user can leave the Session", %{session: session} do
      with uid <- UUID.generate(),
           :ok <- Session.join(session, id: uid, name: "Jane Doe"),
           :ok <- Session.leave(session, uid),
           %Session{users: users} <- Session.get_state(session)
      do
        assert length(users) == 0
      end
    end

    test "It will simply ignore a leave call for a user that does not exist", %{session: session} do
      :ok = Session.leave(session, "does-not-exist")
    end
  end

  describe "#get_state/1" do
    setup [:setup_session]

    test "Returns the current Session state", %{session: session} do
      with uid <- UUID.generate(),
           :ok <- Session.join(session, id: uid, name: "Jane Doe"),
           :ok <- Session.join(session, name: "John Doe"),
           :ok <- Session.toggle_raise(session, uid),
           %Session{id: sid, users: users} <- Session.get_state(session)
      do
        assert sid != nil
        assert length(users) == 2
        assert match?(%User{name: "John Doe", is_raised: false}, Enum.at(users, 0))
        assert match?(%User{name: "Jane Doe", is_raised: true}, Enum.at(users, 1))
      end
    end
  end

  def setup_session(_) do
    {:ok, session} = Session.start()
    [session: session]
  end
end
