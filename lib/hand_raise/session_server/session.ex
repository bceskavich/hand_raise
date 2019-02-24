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

  @derive Jason.Encoder
  defstruct [
    :id,
    users: []
  ]

  @type t() :: %__MODULE__{id: binary(), users: [User.t()]}
  @type session_name() :: {:via, Registry, {SessionRegistry, binary()}}
  @type sid() :: session_name() | pid()

  # DynamicSupervisor management

  @doc """
  Starts an instance of __MODULE__ as a child of HandRaise.SessionServer.DynamicSupervisor.
  This function will result in an invocation of #start_link/1
  """
  @spec start() :: DynamicSupervisor.on_start_child()
  def start() do
    session_id = UUID.generate()
    spec = Supervisor.child_spec({__MODULE__, [id: session_id]}, id: {__MODULE__, session_id})
    DynamicSupervisor.start_child(spec)
  end

  @doc """
  Terminates an instance of __MODULE__ that is a child of
  HandRaise.SessionServer.DynamicSupervisor if no users are left
  """
  @spec terminate_if_empty(session_name()) :: :ok | {:error, :not_found} | {:error, :not_empty}
  def terminate_if_empty(name) do
    case is_alive?(name) do
      true ->
        case get_state(name) do
          %__MODULE__{users: []} ->
            name
            |> get_pid()
            |> DynamicSupervisor.terminate_child()

          _ ->
            {:error, :not_empty}
        end

      false ->
        {:error, :not_found}
    end
  end

  # API

  @spec start_link(list()) :: :ok
  def start_link(kwl \\ []) do
    state = struct(__MODULE__, Map.new(kwl))
    GenServer.start_link(__MODULE__, state, name: build_name(state.id))
  end

  @spec is_alive?(sid()) :: boolean()
  def is_alive?(sid)
  def is_alive?(pid) when is_pid(pid), do: Process.alive?(pid)
  def is_alive?({:via, Registry, {SessionRegistry, _id}} = name) do
    GenServer.whereis(name) != nil
  end

  @spec join(sid(), list()) :: :ok
  def join(sid, opts), do: GenServer.cast(sid, {:join, opts})

  @spec leave(sid(), binary()) :: :ok
  def leave(sid, uid), do: GenServer.cast(sid, {:leave, uid})

  @spec toggle_raise(sid(), binary()) :: :ok
  def toggle_raise(sid, uid), do: GenServer.cast(sid, {:toggle_raise, uid})

  @spec get_state(sid()) :: t()
  def get_state(sid), do: GenServer.call(sid, :get_state)

  @spec get_pid(sid()) :: pid()
  def get_pid(sid)
  def get_pid(pid) when is_pid(pid), do: pid
  def get_pid({:via, Registry, {SessionRegistry, _id}} = name) do
    GenServer.call(name, :get_pid)
  end

  @spec get_name(sid() | binary()) :: session_name()
  def get_name(sid)
  def get_name({:via, Registry, {SessionRegistry, _id}} = name), do: name
  def get_name(uuid) when is_binary(uuid), do: build_name(uuid)
  def get_name(pid) when is_pid(pid) do
    with %__MODULE__{id: id} <- get_state(pid) do
      build_name(id)
    end
  end

  # Callbacks

  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
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
