defmodule OmegaBravera.PostgresListener do
  use GenServer
  alias Postgrex.Notifications
  @group_chat_message_deleted_channel "group_chat_message_deleted"
  @private_chat_message_deleted_channel "private_chat_message_deleted"

  defstruct [:pm_ref, :ref, :pid]

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    # use same options to connect to postgres as the Repo does
    {:ok, pid} = Notifications.start_link(OmegaBravera.Repo.config())
    ref = Notifications.listen!(pid, @group_chat_message_deleted_channel)
    pm_ref = Notifications.listen!(pid, @private_chat_message_deleted_channel)
    {:ok, %__MODULE__{pid: pid, ref: ref, pm_ref: pm_ref}}
  end

  def handle_info(
        {:notification, pid, ref, @group_chat_message_deleted_channel, payload},
        %{ref: ref, pid: pid} = state
      ) do
    {:ok, %{"message" => %{"id" => message_id, "group_id" => group_id}}} = Jason.decode(payload)
    broadcast_deletion(message_id, group_id)
    {:noreply, state}
  end

  def handle_info(
        {:notification, pid, pm_ref, @private_chat_message_deleted_channel, payload},
        %{pm_ref: pm_ref, pid: pid} = state
      ) do
    {:ok,
     %{
       "message" => %{
         "id" => message_id,
         "from_user_id" => from_user_id,
         "to_user_id" => to_user_id
       }
     }} = Jason.decode(payload)

    broadcast_deletion(message_id, from_user_id, to_user_id)
    {:noreply, state}
  end

  def broadcast_deletion(message_id, group_id),
    do:
      OmegaBraveraWeb.Endpoint.broadcast("group_channel:#{group_id}", "deleted_message", %{
        message: %{id: message_id, group_id: group_id}
      })

  def broadcast_deletion(message_id, from_user_id, to_user_id) do
    OmegaBraveraWeb.Endpoint.broadcast(
      "user_channel:#{from_user_id}",
      "deleted_private_message",
      %{
        message: %{id: message_id, chat_id: to_user_id}
      }
    )

    OmegaBraveraWeb.Endpoint.broadcast("user_channel:#{to_user_id}", "deleted_private_message", %{
      message: %{id: message_id, chat_id: from_user_id}
    })
  end

  def terminate(_reason, %{ref: ref, pid: pid, pm_ref: pm_ref}) do
    Notifications.unlisten!(pid, ref)
    Notifications.unlisten!(pid, pm_ref)
    :ok
  end
end
