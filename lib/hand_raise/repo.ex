defmodule HandRaise.Repo do
  use Ecto.Repo,
    otp_app: :hand_raise,
    adapter: Ecto.Adapters.Postgres
end
