defmodule HandRaise.SessionServer.User do
  alias Ecto.UUID

  @derive Jason.Encoder
  defstruct [
    :name,
    :id,
    is_raised: false
  ]

  @type t() :: %__MODULE__{
    name: binary(),
    id: binary(),
    is_raised: boolean()
  }

  def new(kwl \\ []) do
    opts =
      kwl
      |> Map.new()
      |> Map.put_new(:id, UUID.generate())

    struct(__MODULE__, opts)
  end

  def find(users, uid), do: Enum.find(users, & &1.id == uid)

  def toggle_raised(%__MODULE__{is_raised: is_raised} = user) do
    %__MODULE__{user | is_raised: !is_raised}
  end
end
