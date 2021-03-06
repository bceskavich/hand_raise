defmodule HandRaise.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      HandRaise.Repo,
      # Start the endpoint when the application starts
      HandRaiseWeb.Endpoint,
      HandRaise.Presence,
      # The supervision tree for managing app sessions
      HandRaise.SessionServer.DynamicSupervisor,
      # The Registry for storing session names
      {Registry, keys: :unique, name: HandRaise.SessionServer.SessionRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HandRaise.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HandRaiseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
