defmodule HandRaise.Presence do
  use Phoenix.Presence,
    otp_app: :hand_raise,
    pubsub_server: HandRaise.PubSub
end
