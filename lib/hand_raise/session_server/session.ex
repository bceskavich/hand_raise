defmodule HandRaise.SessionServer.Session do
  @moduledoc """
  GenServer implementation to encapsulate a HandRaise Session, plus an API for
  interacting with Sessions. Tracks membership state (i.e. `users`), including
  whether or not a user has their hand raised.
  """

  use GenServer

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

  @id_chars ~w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

  @type t() :: %__MODULE__{id: binary(), users: [User.t()]}
  @type session_name() :: {:via, Registry, {SessionRegistry, binary()}}
  @type sname() :: session_name() | pid()

  # DynamicSupervisor management

  @doc """
  Starts an instance of __MODULE__ as a child of HandRaise.SessionServer.DynamicSupervisor.
  This function will result in an invocation of #start_link/1
  """
  @spec start() :: DynamicSupervisor.on_start_child()
  def start() do
    session_id = generate_session_id()
    spec = Supervisor.child_spec({__MODULE__, [id: session_id]}, id: {__MODULE__, session_id})
    DynamicSupervisor.start_child(spec)
  end

  defp generate_session_id() do
    sid =
      (1..6)
      |> Enum.map(fn _ -> Enum.random(@id_chars) end)
      |> Enum.join("")

    sid
    |> build_name()
    |> is_alive?()
    |> case do
      true -> generate_session_id()
      false -> sid
    end
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

  @spec is_alive?(sname()) :: boolean()
  def is_alive?(sname)
  def is_alive?(pid) when is_pid(pid), do: Process.alive?(pid)
  def is_alive?({:via, Registry, {SessionRegistry, _id}} = name) do
    GenServer.whereis(name) != nil
  end

  @spec join(sname(), list()) :: :ok
  def join(sname, opts), do: GenServer.call(sname, {:join, opts})

  @spec leave(sname(), binary()) :: :ok
  def leave(sname, uid), do: GenServer.call(sname, {:leave, uid})

  @spec toggle_raise(sname(), binary()) :: :ok
  def toggle_raise(sname, uid), do: GenServer.call(sname, {:toggle_raise, uid})

  @spec get_state(sname()) :: t()
  def get_state(sname), do: GenServer.call(sname, :get_state)

  @spec get_pid(sname()) :: pid()
  def get_pid(sname)
  def get_pid(pid) when is_pid(pid), do: pid
  def get_pid({:via, Registry, {SessionRegistry, _id}} = name) do
    GenServer.call(name, :get_pid)
  end

  @spec get_name(sname() | binary()) :: session_name()
  def get_name(sname)
  def get_name({:via, Registry, {SessionRegistry, _id}} = name), do: name
  def get_name(sid) when is_binary(sid), do: build_name(sid)
  def get_name(pid) when is_pid(pid) do
    with %__MODULE__{id: id} <- get_state(pid) do
      build_name(id)
    end
  end

  # Callbacks

  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  def handle_call({:join, opts}, _from, %__MODULE__{users: users} = state) do
    state = %__MODULE__{state | users: [User.new(opts) | users]}
    {:reply, state, state}
  end
  def handle_call({:leave, uid}, _from, %__MODULE__{users: users} = state) do
    users = users |> Enum.filter(&(&1.id != uid))
    state = %__MODULE__{state | users: users}
    {:reply, state, state}
  end
  def handle_call({:toggle_raise, uid}, _from, %__MODULE__{users: users} = state) do
    users =
      users
      |> Enum.map(fn
        %User{id: id} = user when id == uid -> User.toggle_raised(user)
        user -> user
      end)

    state = %__MODULE__{state | users: users}

    {:reply, state, state}
  end
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
  end

  # Helpers

  defp build_name(id), do: {:via, Registry, {SessionRegistry, id}}
end
