defmodule HandRaise.SessionServer.DynamicSupervisor do
  @moduledoc """
  Supervision tree for HandRaise.SessionServer.Session servers. We use a
  DynamicSupervisor so that we can start Sessions on demand.
  """

  use DynamicSupervisor

  # API

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  # Callbacks

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
