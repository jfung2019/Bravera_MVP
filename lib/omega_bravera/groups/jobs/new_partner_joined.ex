defmodule OmegaBravera.Groups.Jobs.NewPartnerJoined do
  @moduledoc """
  Send email to Org Admin every day about the users that joined that day
  """

  use Oban.Worker, queue: :default

  alias OmegaBravera.{Accounts, Accounts.Notifier}

  @impl Oban.Worker
  def perform(_args, _job) do
    Accounts.list_orgs_with_new_members()
    |> Enum.each(&email_org_members(&1))

    :ok
  end

  def email_org_members(%{organization_members: members}) do
    members
    |> Enum.each(&Notifier.notify_org_admin_new_members(&1.partner_user))
  end
end
