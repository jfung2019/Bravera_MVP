defmodule OmegaBravera.IngestionSupervisor do
  use DynamicSupervisor
  alias OmegaBravera.IngestionProcessor

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(_arg), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_processing(params),
    do:
      DynamicSupervisor.start_child(__MODULE__, %{
        id: IngestionProcessor,
        start: {IngestionProcessor, :start_link, [params]},
        restart: :transient
      })
end
