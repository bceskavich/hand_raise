defmodule HandRaise.SessionServer.Session do
  @moduledoc """
  GenServer implementation to encapsulate a HandRaise Session, plus an API for
  interacting with Sessions. Tracks membership state (i.e. `users`), including
  whether or not a user has their hand raised.
  """

  use GenServer

  alias Ecto.UUID
  alias HandRaise.SessionServer.{
    DynamicSupervisor,
    User,
    SessionRegistry
  }

  defstruct [
    :id,
    users: []
  ]

  # DynamicSupervisor management

  @doc """
  Starts an instance of __MODULE__ as a child of HandRaise.SessionServer.DynamicSupervisor.
  This function will result in an invocation of #start_link/1
  """
  def start() do
    session_id = UUID.generate()
    spec = Supervisor.child_spec({__MODULE__, [id: session_id]}, id: {__MODULE__, session_id})
    DynamicSupervisor.start_child(spec)
  end

  @doc """
  Terminates an instance of __MODULE__ that is a child of HandRaise.SessionServer.DynamicSupervisor
  """
  def terminate(pid), do: DynamicSupervisor.terminate_child(pid)

  # API

  def start_link(kwl \\ []) do
    state = struct(__MODULE__, Map.new(kwl))
    GenServer.start_link(__MODULE__, state, name: build_name(state.id))
  end

  def is_alive?(pid), do: GenServer.whereis(pid) != nil

  def join(pid, opts), do: GenServer.cast(pid, {:join, opts})

  def leave(pid, uid), do: GenServer.cast(pid, {:leave, uid})

  def toggle_raise(pid, uid), do: GenServer.cast(pid, {:toggle_raise, uid})

  def get_state(pid), do: GenServer.call(pid, :get_state)

  def get_name({:via, Registry, {SessionRegistry, _id}} = name), do: name
  def get_name(uuid) when is_binary(uuid), do: build_name(uuid)
  def get_name(pid) when is_pid(pid) do
    with %__MODULE__{id: id} <- get_state(pid) do
      build_name(id)
    else
      err -> err
    end
  end

  # Callbacks

  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:join, opts}, %__MODULE__{users: users} = state) do
    {:noreply, %__MODULE__{state | users: [User.new(opts) | users]}}
  end
  def handle_cast({:leave, uid}, %__MODULE__{users: users} = state) do
    next_users = users |> Enum.filter(&(&1.id != uid))
    {:noreply, %__MODULE__{state | users: next_users}}
  end
  def handle_cast({:toggle_raise, uid}, %__MODULE__{users: users} = state) do
    next_users =
      users
      |> Enum.map(fn
        %User{id: id} = user when id == uid -> User.toggle_raised(user)
        user -> user
      end)

    {:noreply, %__MODULE__{state | users: next_users}}
  end

  # Helpers

  defp build_name(id), do: {:via, Registry, {SessionRegistry, id}}
end
