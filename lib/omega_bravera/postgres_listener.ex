defmodule OmegaBravera.PostgresListener do
  use GenServer
  alias Postgrex.Notifications
  @group_chat_message_deleted_channel "group_chat_message_deleted"

  defstruct [:ref, :pid]

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    # use same options to connect to postgres as the Repo does
    {:ok, pid} = Notifications.start_link(OmegaBravera.Repo.config())
    ref = Notifications.listen!(pid, @group_chat_message_deleted_channel)
    {:ok, %__MODULE__{pid: pid, ref: ref}}
  end

  def handle_info(
        {:notification, pid, ref, @group_chat_message_deleted_channel, payload},
        %{ref: ref, pid: pid} = state
      ) do
    {:ok, %{"message" => %{"id" => message_id, "group_id" => group_id}}} = Jason.decode(payload)
    broadcast_deletion(message_id, group_id)
    {:noreply, state}
  end

  def broadcast_deletion(message_id, group_id), do: OmegaBraveraWeb.Endpoint.broadcast("group_channel:#{group_id}", "deleted_message", %{message: %{id: message_id, group_id: group_id}})

  def terminate(_reason, %{ref: ref, pid: pid}) do
    Notifications.unlisten!(pid, ref)
    :ok
  end
end
