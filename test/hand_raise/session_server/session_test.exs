defmodule HandRaise.SessionServer.SessionTest do
  use HandRaise.DataCase

  alias Ecto.UUID
  alias HandRaise.SessionServer.{
    DynamicSupervisor,
    Session,
    SessionRegistry,
    User
  }

  describe "#start/0" do
    test "It starts an empty Session managed by HandRaise.SessionServer.DynamicSupervisor" do
      {:ok, _} = Session.start()
    end
  end

  describe "#is_alive?/1" do
    test "Returns if the session GenServer is running" do
      {:ok, session} = Session.start()
      name = Session.get_name(session)

      assert Session.is_alive?(session)
      assert Session.is_alive?(name)

      DynamicSupervisor.terminate_child(session)

      assert !Session.is_alive?(session)
      assert !Session.is_alive?(name)
    end
  end

  describe "#terminate_if_empty/1" do
    setup [:setup_session]

    test "It returns an error if the session isn't alive", %{session: session} do
      name = Session.get_name(session)
      DynamicSupervisor.terminate_child(session)
      assert match?({:error, :not_found}, Session.terminate_if_empty(name))
    end

    test "It returns an error if the session still has users", %{session: session} do
      name = Session.get_name(session)
      Session.join(name, name: "Jane Doe")

      assert match?({:error, :not_empty}, Session.terminate_if_empty(name))
    end

    test "It terminates the session if empty", %{session: session} do
      name = Session.get_name(session)
      assert match?(:ok, Session.terminate_if_empty(name))
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

  describe "#get_pid/1" do
    setup [:setup_session]

    test "It returns the pid as is if it's a pid", %{session: session} do
      assert session == Session.get_pid(session)
    end

    test "It gets the pid for the session name", %{session: session} do
      assert session == session |> Session.get_name() |> Session.get_pid()
    end
  end

  describe "#join/2" do
    setup [:setup_session]

    test "A new user can join the Session", %{session: session} do
      with uid <- UUID.generate(),
           %Session{users: [user]} <- Session.join(session, id: uid, name: "Jane Doe")
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
           %Session{} <- Session.join(session, id: uid, name: "Jane Doe"),
           %Session{users: [user]} <- Session.toggle_raise(session, uid)
      do
        assert user.is_raised
      end
    end

    test "It will simply ignore a toggle for a user that does not exist", %{session: session} do
      %Session{} = Session.toggle_raise(session, "does-not-exist")
    end
  end

  describe "#leave/2" do
    setup [:setup_session]

    test "A user can leave the Session", %{session: session} do
      with uid <- UUID.generate(),
           %Session{} <- Session.join(session, id: uid, name: "Jane Doe"),
           %Session{users: users} <- Session.leave(session, uid)
      do
        assert length(users) == 0
      end
    end

    test "It will simply ignore a leave call for a user that does not exist", %{session: session} do
      %Session{} = Session.leave(session, "does-not-exist")
    end
  end

  describe "#get_state/1" do
    setup [:setup_session]

    test "Returns the current Session state", %{session: session} do
      with uid <- UUID.generate(),
           %Session{} <- Session.join(session, id: uid, name: "Jane Doe"),
           %Session{} <- Session.join(session, name: "John Doe"),
           %Session{} <- Session.toggle_raise(session, uid),
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
