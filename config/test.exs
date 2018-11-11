use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hand_raise, HandRaiseWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :hand_raise, HandRaise.Repo,
  username: "postgres",
  password: "postgres",
  database: "hand_raise_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
