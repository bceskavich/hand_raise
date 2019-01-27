defmodule HandRaise.SessionServer.User do
  alias Ecto.UUID

  defstruct [
    :name,
    :id,
    is_raised: false
  ]

  def new(kwl \\ []) do
    struct(__MODULE__, Map.new(kwl))
    |> Map.put(:id, UUID.generate())
  end

  def find(users, id) do
    users
    |> Enum.find(fn %__MODULE__{id: uid} -> uid == id end)
  end

  def toggle_raised(%__MODULE__{is_raised: is_raised} = user) do
    %__MODULE__{user | is_raised: !is_raised}
  end
end
