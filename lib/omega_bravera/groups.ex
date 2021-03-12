defmodule OmegaBravera.Groups do
  @endpoint OmegaBraveraWeb.Endpoint
  @user_channel OmegaBraveraWeb.UserChannel
  @moduledoc """
  The Partners context.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias OmegaBravera.Repo
  alias Absinthe.Relay

  alias OmegaBravera.Groups.{Partner, Member, OfferPartner, ChatMessage, GroupApproval}
  alias OmegaBravera.Accounts.Notifier
  alias OmegaBravera.Notifications.Jobs.NotifyNewMessage

  @doc """
  Admin dashboard groups information
  """
  def admin_dashboard_groups_info() do
    from(p in Partner,
      select: %{
        total_groups: fragment("TO_CHAR(?, '999,999')", count(p.id)),
        live_groups:
          fragment("TO_CHAR(?, '999,999')", filter(count(p.id), p.approval_status == :approved))
      }
    )
    |> Repo.one()
  end

  @doc """
  Returns the list of partner.

  ## Examples

      iex> list_partner()
      [%Partner{}, ...]

  """
  def list_partner do
    Repo.all(Partner)
  end

  def paginate_groups(organization_id, params) do
    from(p in Partner, where: p.organization_id == ^organization_id)
    |> Turbo.Ecto.turbo(params, entry_name: "partners")
  end

  def organization_group_count(organization_id) do
    from(p in Partner, where: p.organization_id == ^organization_id, select: count(p.id))
    |> Repo.one()
  end

  @doc """
  Returns tuple of partners ready for dropdown list.
  """
  def partner_options do
    from(p in Partner, select: {p.name, p.id}) |> Repo.all()
  end

  @doc """
  Gets a single partner.

  Raises `Ecto.NoResultsError` if the Partner does not exist.

  ## Examples

      iex> get_partner!(123)
      %Partner{}

      iex> get_partner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_partner!(id) do
    from(p in Partner,
      distinct: true,
      left_join: o in assoc(p, :offers),
      where: p.id == ^id,
      select: %{
        p
        | type:
            fragment(
              "CASE WHEN ? is null then ? else ? end",
              o.id,
              "suggested_partner",
              "bravera_partner"
            )
      }
    )
    |> Repo.one!()
    |> Repo.preload([:location, :offers, :organization])
  end

  @doc """
  Get partners a partner and shows whether that user is a member
  of that partner.
  """
  def get_partner_with_membership!(id, user_id) do
    from(p in Partner,
      as: :group,
      left_lateral_join:
        o in subquery(
          from(o in OmegaBravera.Offers.Offer,
            inner_join: op in assoc(o, :offer_partners),
            where: op.partner_id == parent_as(:group).id and o.approval_status == :approved,
            order_by: [desc: :inserted_at],
            limit: 1,
            select: %{id: o.id, partner_id: op.partner_id}
          )
        ),
      on: o.partner_id == p.id,
      left_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      where: p.id == ^id,
      order_by: [desc: p.inserted_at],
      select: %{
        p
        | type:
            fragment(
              "CASE WHEN ? is null then ? else ? end",
              o.id,
              "suggested_partner",
              "bravera_partner"
            ),
          is_member: fragment("CASE WHEN ? THEN ? ELSE ? END", is_nil(m.id), false, true)
      }
    )
    |> Repo.one!()
  end

  defp list_partners_with_membership_query(user_id) do
    from(p in Partner,
      as: :group,
      left_lateral_join:
        o in subquery(
          from(o in OmegaBravera.Offers.Offer,
            inner_join: op in assoc(o, :offer_partners),
            where: op.partner_id == parent_as(:group).id and o.approval_status == :approved,
            order_by: [desc: :inserted_at],
            limit: 1,
            select: %{id: o.id, partner_id: op.partner_id}
          )
        ),
      on: o.partner_id == p.id,
      left_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      where: p.approval_status == :approved,
      order_by: [desc: p.inserted_at],
      select: %{
        p
        | type:
            fragment(
              "CASE WHEN ? is null then ? else ? end",
              o.id,
              "suggested_partner",
              "bravera_partner"
            ),
          is_member: fragment("CASE WHEN ? THEN ? ELSE ? END", is_nil(m.id), false, true)
      }
    )
  end

  def list_partners_with_membership(user_id) do
    list_partners_with_membership_query(user_id)
    |> Repo.all()
  end

  def list_partners_with_membership_paginated(user_id, pagination_args) do
    list_partners_with_membership_query(user_id)
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def search_groups_paginated(user_id, keyword, global, location_id, pagination_args) do
    search = "%#{keyword}%"

    list_partners_with_membership_query(user_id)
    |> where([p], ilike(p.name, ^search))
    |> search_location(global, location_id)
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  defp search_location(query, false, location_id) do
    from(q in query,
      where: q.location_id == ^location_id
    )
  end

  defp search_location(query, true, _location_id), do: query

  def total_groups() do
    from(p in Partner, select: count(p.id))
    |> Repo.one()
  end

  def check_empty_live_group_offer(organization_id) do
    from(p in Partner,
      left_join: o in assoc(p, :offers),
      left_join: m in assoc(p, :members),
      where:
        p.organization_id == ^organization_id and p.approval_status == :approved and
          o.approval_status == :approved,
      group_by: [p.id],
      having: count(m.id) == 0,
      select: count(p.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  check if there is new group added since the given datetime
  """
  @spec new_group_since(Datetime.t()) :: boolean()
  def new_group_since(nil), do: false

  def new_group_since(datetime) do
    from(p in Partner, where: p.inserted_at > ^datetime, select: count(p.id) > 0)
    |> Repo.one()
  end

  @doc """
  Creates a partner.

  ## Examples

      iex> create_partner(%{field: value})
      {:ok, %Partner{}}

      iex> create_partner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_partner(attrs \\ %{}) do
    %Partner{}
    |> Partner.changeset(attrs)
    |> Repo.insert()
  end

  def create_org_partner(attrs \\ %{}) do
    result =
      %Partner{}
      |> Partner.org_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, partner} ->
        OmegaBravera.Accounts.get_partner_user_email_by_group(partner.id)
        |> Notifier.customer_group_modified_email(partner)

      _ ->
        :ok
    end

    result
  end

  def create_group_approval(attrs \\ %{}) do
    case GroupApproval.changeset(%GroupApproval{}, attrs) do
      %{valid?: true} = changeset ->
        group_approval =
          changeset
          |> Ecto.Changeset.apply_changes()

        {:ok, _partner} =
          get_partner!(group_approval.group_id)
          |> update_partner(%{approval_status: group_approval.status})

        {:ok, group_approval}

      changeset ->
        {:error, changeset}
    end
  end

  def change_group_approval(%GroupApproval{} = group_approval, attr \\ %{}) do
    GroupApproval.changeset(group_approval, attr)
  end

  @doc """
  Updates a partner.

  ## Examples

      iex> update_partner(partner, %{field: new_value})
      {:ok, %Partner{}}

      iex> update_partner(partner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_partner(%Partner{} = partner, attrs) do
    result =
      partner
      |> Partner.changeset(attrs)
      |> Repo.update()

    case {partner.approval_status, result} do
      # If no Organization, then we don't care.
      {_, {:ok, %{organization_id: nil}} = result} ->
        result

      # If org and from pending to approved or denied
      {:pending, {:ok, %{approval_status: status} = updated_partner} = result}
      when status in [:approved, :denied] ->
        OmegaBravera.Accounts.get_partner_user_email_by_group(updated_partner.id)
        |> Notifier.notify_customer_group_email(updated_partner, %GroupApproval{
          status: status,
          message: ""
        })

        result

      {_, result} ->
        result
    end
  end

  def update_org_partner(%Partner{} = partner, attrs) do
    partner
    |> Partner.org_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a partner.

  ## Examples

      iex> delete_partner(partner)
      {:ok, %Partner{}}

      iex> delete_partner(partner)
      {:error, %Ecto.Changeset{}}

  """
  def delete_partner(%Partner{} = partner), do: Repo.delete(partner)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking partner changes.

  ## Examples

      iex> change_partner(partner)
      %Ecto.Changeset{source: %Partner{}}

  """
  def change_partner(%Partner{} = partner, attrs \\ %{}), do: Partner.changeset(partner, attrs)

  alias OmegaBravera.Groups.PartnerLocation

  @doc """
  Returns the list of partner_locations.

  ## Examples

      iex> list_partner_locations()
      [%PartnerLocation{}, ...]

  """
  def list_partner_locations do
    from(l in PartnerLocation,
      left_join: p in assoc(l, :partner),
      where: p.approval_status == :approved
    )
    |> Repo.all()
  end

  @doc """
  List partner_locations within 50km of the given coordinate
  """
  @spec list_partner_locations(integer(), integer()) :: [PartnerLocation.t()]
  def list_partner_locations(longitude, latitude) do
    geom = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}

    from(l in PartnerLocation,
      left_join: p in assoc(l, :partner),
      where: p.approval_status == :approved and st_dwithin_in_meters(l.geom, ^geom, 50000)
    )
    |> Repo.all()
  end

  @doc """
  Gets a single partner_location.

  Raises `Ecto.NoResultsError` if the Partner location does not exist.

  ## Examples

      iex> get_partner_location!(123)
      %PartnerLocation{}

      iex> get_partner_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_partner_location!(id), do: Repo.get!(PartnerLocation, id)

  @doc """
  Creates a partner_location.

  ## Examples

      iex> create_partner_location(%{field: value})
      {:ok, %PartnerLocation{}}

      iex> create_partner_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_partner_location(attrs \\ %{}) do
    %PartnerLocation{}
    |> PartnerLocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a partner_location.

  ## Examples

      iex> update_partner_location(partner_location, %{field: new_value})
      {:ok, %PartnerLocation{}}

      iex> update_partner_location(partner_location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_partner_location(%PartnerLocation{} = partner_location, attrs) do
    partner_location
    |> PartnerLocation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a partner_location.

  ## Examples

      iex> delete_partner_location(partner_location)
      {:ok, %PartnerLocation{}}

      iex> delete_partner_location(partner_location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_partner_location(%PartnerLocation{} = partner_location) do
    Repo.delete(partner_location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking partner_location changes.

  ## Examples

      iex> change_partner_location(partner_location)
      %Ecto.Changeset{source: %PartnerLocation{}}

  """
  def change_partner_location(%PartnerLocation{} = partner_location) do
    PartnerLocation.changeset(partner_location, %{})
  end

  def organization_locations_count(organization_id) do
    from(l in PartnerLocation,
      left_join: p in assoc(l, :partner),
      where: p.organization_id == ^organization_id,
      select: count(l.id)
    )
    |> Repo.one()
  end

  alias OmegaBravera.Groups.PartnerVote

  @doc """
  Returns the list of partner_votes.

  ## Examples

      iex> list_partner_votes()
      [%PartnerVote{}, ...]

  """
  def list_partner_votes do
    Repo.all(PartnerVote)
  end

  @doc """
  Returns the list of partner_votes scoped to a partner.
  """
  def get_partner_votes(partner_id) do
    from(v in PartnerVote, where: v.partner_id == ^partner_id)
    |> Repo.all()
  end

  @doc """
  Gets a single partner_vote.

  Raises `Ecto.NoResultsError` if the Partner vote does not exist.

  ## Examples

      iex> get_partner_vote!(123)
      %PartnerVote{}

      iex> get_partner_vote!(456)
      ** (Ecto.NoResultsError)

  """
  def get_partner_vote!(id), do: Repo.get!(PartnerVote, id)

  @doc """
  Creates a partner_vote.

  ## Examples

      iex> create_partner_vote(%{field: value})
      {:ok, %PartnerVote{}}

      iex> create_partner_vote(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_partner_vote(attrs \\ %{}) do
    %PartnerVote{}
    |> PartnerVote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a partner_vote.

  ## Examples

      iex> delete_partner_vote(partner_vote)
      {:ok, %PartnerVote{}}

      iex> delete_partner_vote(partner_vote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_partner_vote(%PartnerVote{} = partner_vote) do
    Repo.delete(partner_vote)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking partner_vote changes.

  ## Examples

      iex> change_partner_vote(partner_vote)
      %Ecto.Changeset{source: %PartnerVote{}}

  """
  def change_partner_vote(%PartnerVote{} = partner_vote),
    do: PartnerVote.changeset(partner_vote, %{})

  @doc """
  Allows a user to join a partner to be a member.
  """
  def join_partner(partner_id, user_id) do
    partner = get_partner!(partner_id)
    user = OmegaBravera.Accounts.get_user!(user_id)

    case check_partner_email_restriction(partner, user) do
      true ->
        %Member{}
        |> Member.changeset(%{user_id: user_id, partner_id: partner_id})
        |> Repo.insert()
        |> broadcast_join_partner()

      _ ->
        {:error, :email_restricted}
    end
  end

  defp broadcast_join_partner({:ok, %{user_id: user_id, partner_id: group_id}} = result) do
    @endpoint.broadcast(@user_channel.user_channel(user_id), "joined_group", %{id: group_id})
    result
  end

  defp broadcast_join_partner(result), do: result

  defp check_partner_email_restriction(%{email_restriction: nil}, _user), do: true

  defp check_partner_email_restriction(%{email_restriction: email_suffix}, %{email: email}) do
    [_prefix, suffix] = String.split(email, "@")
    trim_and_downcase(email_suffix) == trim_and_downcase(suffix)
  end

  defp check_partner_email_restriction(_partner, _user), do: false

  defp trim_and_downcase(word), do: word |> String.trim() |> String.downcase()

  @doc """
  Lists all members from a partner ID.
  """
  def list_partner_members(partner_id) do
    list_partner_members_query(partner_id)
    |> Repo.all()
  end

  def list_partner_members_query(partner_id) do
    from(m in Member, where: m.partner_id == ^partner_id, preload: [user: [:strava]])
  end

  @doc """
  Gets a partner member by their ID.
  """
  def get_partner_member!(member_id), do: Repo.get!(Member, member_id)

  @doc """
  Get group member using group id and user id
  """
  @spec get_group_member_by_group_id_user_id(String.t(), String.t()) :: Member.t()
  def get_group_member_by_group_id_user_id(group_id, user_id) do
    from(m in Member, where: m.user_id == ^user_id and m.partner_id == ^group_id)
    |> Repo.one()
  end

  @doc """
  update group member
  """
  @spec update_group_member(Member.t(), map()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def update_group_member(%Member{} = member, attrs \\ %{}) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  mute notification for group member
  """
  @spec mute_group(Member.t(), map()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def mute_group(%Member{} = member, attrs \\ %{}) do
    member
    |> Member.mute_notification_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete partner member.
  """
  def delete_partner_member(member) do
    Repo.delete(member)

    @endpoint.broadcast(@user_channel.user_channel(member.user_id), "removed_group", %{
      id: member.partner_id
    })
  end

  @doc """
  Gets a partner from the ID plus the password.
  """
  def get_partner_with_password(partner_id, nil) do
    from(p in Partner, where: p.id == ^partner_id and is_nil(p.join_password))
    |> Repo.one()
  end

  def get_partner_with_password(partner_id, password) do
    from(p in Partner, where: p.id == ^partner_id and p.join_password == ^password)
    |> Repo.one()
  end

  def check_offer_not_attached(org_id) do
    from(
      o in OmegaBravera.Offers.Offer,
      left_join: op in assoc(o, :offer_partners),
      where: o.organization_id == ^org_id and is_nil(op.id),
      select: count(o.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  Get the partners joined by the user.
  """
  def list_joined_partners(user_id) do
    from(p in Partner,
      left_join: m in assoc(p, :members),
      where: m.user_id == ^user_id and p.approval_status == :approved
    )
    |> Repo.all()
  end

  @doc """
  Get the partners joined by the user, along with the latest 10 messages.
  """
  def list_joined_partners_with_chat_messages(user_id, message_count \\ 10) do
    from(p in Partner,
      as: :group,
      left_join: m in assoc(p, :members),
      left_join: me in assoc(p, :chat_messages),
      left_join: u in assoc(m, :user),
      left_lateral_join:
        last_messages in subquery(
          from(ChatMessage,
            where: [group_id: parent_as(:group).id],
            order_by: [desc: :inserted_at],
            limit: ^message_count,
            select: [:id]
          )
        ),
      on: last_messages.id == me.id and not is_nil(last_messages.id),
      left_lateral_join:
        muted in subquery(
          from(m in Member,
            where: m.user_id == ^user_id and parent_as(:group).id == m.partner_id,
            select: %{partner_id: m.partner_id, mute_notification: m.mute_notification}
          )
        ),
      on: muted.partner_id == p.id,
      where: m.user_id == ^user_id and p.approval_status == :approved,
      preload: [chat_messages: {me, [:user, reply_to_message: :user]}, users: u],
      select: %{p | is_muted: not is_nil(muted.mute_notification)}
    )
    |> Repo.all()
  end

  @doc """
  Get the partner joined by the user, along with the latest 10 messages.
  """
  @spec list_joined_partner_with_chat_messages(integer(), integer(), integer()) ::
          Partner.t() | nil
  def list_joined_partner_with_chat_messages(partner_id, user_id, message_count \\ 10) do
    from(p in Partner,
      as: :group,
      left_join: m in assoc(p, :members),
      left_join: me in assoc(p, :chat_messages),
      left_join: u in assoc(m, :user),
      left_lateral_join:
        last_messages in subquery(
          from(ChatMessage,
            where: [group_id: parent_as(:group).id],
            order_by: [desc: :inserted_at],
            limit: ^message_count,
            select: [:id]
          )
        ),
      on: last_messages.id == me.id and not is_nil(last_messages.id),
      left_lateral_join:
        muted in subquery(
          from(m in Member,
            where: m.user_id == ^user_id and m.partner_id == ^partner_id,
            select: %{partner_id: m.partner_id, mute_notification: m.mute_notification}
          )
        ),
      on: muted.partner_id == p.id,
      where: p.id == ^partner_id and p.approval_status == :approved,
      preload: [chat_messages: {me, [:user, reply_to_message: :user]}, users: u],
      select: %{p | is_muted: muted.mute_notification}
    )
    |> Repo.one()
  end

  @doc """
  Allows a partner to be joined to an offer.
  """
  def create_offer_partner(attrs) do
    %OfferPartner{}
    |> OfferPartner.changeset(attrs)
    |> Repo.insert()
  end

  defp submit_offer_partner_for_approval(%{id: offer_id} = offer) do
    OmegaBravera.Accounts.get_partner_user_email_by_offer(offer_id)
    |> Notifier.customer_offer_modified_email(offer)
  end

  def create_org_offer_partner(attrs) do
    result = create_offer_partner(attrs)

    case result do
      {:ok, %{offer_id: offer_id}} ->
        OmegaBravera.Offers.get_offer!(offer_id)
        |> submit_offer_partner_for_approval()

      _ ->
        :ok
    end

    result
  end

  def resubmit_offer_partner_for_approval(offer_id) do
    offer = OmegaBravera.Offers.get_offer!(offer_id)

    case OmegaBravera.Offers.update_offer(offer, %{approval_status: :pending}) do
      {:ok, _} ->
        submit_offer_partner_for_approval(offer)

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  @doc """
  Gets an offer partner by ID.
  """
  def get_offer_partner!(id), do: Repo.get!(OfferPartner, id)

  @doc """
  Deletes an offer partner.
  """
  def delete_offer_partner(offer_partner), do: Repo.delete(offer_partner)

  @doc """
  Define dataloader for ecto.
  """
  def datasource(default_params),
    do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: default_params)

  def query(Partner, %{scope: :partner_type, current_user: %{id: user_id}}) do
    from(p in Partner,
      distinct: true,
      left_join: o in assoc(p, :offers),
      on: o.approval_status == :approved,
      left_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      select: %{
        p
        | type:
            fragment(
              "CASE WHEN ? is null then ? else ? end",
              o.id,
              "suggested_partner",
              "bravera_partner"
            ),
          is_member: fragment("CASE WHEN ? THEN ? ELSE ? END", is_nil(m.id), false, true)
      }
    )
  end

  def query(queryable, _), do: queryable

  @doc """
  Returns the list of group_chat_messages.

  ## Examples

      iex> list_group_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_group_chat_messages do
    Repo.all(ChatMessage)
  end

  @doc """
  Gets a single chat_message.

  Raises `Ecto.NoResultsError` if the Chat message does not exist.

  ## Examples

      iex> get_chat_message!(123)
      %ChatMessage{}

      iex> get_chat_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_message!(id) do
    from(m in ChatMessage, where: m.id == ^id, preload: [:user, reply_to_message: :user])
    |> Repo.one!()
  end

  @doc """
  Get chat message by id and preload group
  """
  @spec get_chat_message_with_group!(String.t()) :: ChatMessage.t()
  def get_chat_message_with_group!(id) do
    from(m in ChatMessage, where: m.id == ^id, preload: [:group])
    |> Repo.one!()
  end

  @doc """
  Creates a chat_message.

  ## Examples

      iex> create_chat_message(%{field: value})
      {:ok, %ChatMessage{}}

      iex> create_chat_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_message(attrs \\ %{}) do
    %ChatMessage{}
    |> ChatMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Insert new oban job when new chat message is inserted for sending notification
  """
  @spec notify_new_message(ChatMessage.t()) :: ChatMessage.t()
  def notify_new_message(%ChatMessage{} = message) do
    message
    |> NotifyNewMessage.new()
    |> Oban.insert()

    message
  end

  def notify_new_message(message), do: message

  @doc """
  Updates a chat_message.

  ## Examples

      iex> update_chat_message(chat_message, %{field: new_value})
      {:ok, %ChatMessage{}}

      iex> update_chat_message(chat_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_message(%ChatMessage{} = chat_message, attrs) do
    chat_message
    |> ChatMessage.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_message.

  ## Examples

      iex> delete_chat_message(chat_message)
      {:ok, %ChatMessage{}}

      iex> delete_chat_message(chat_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_message(%ChatMessage{} = chat_message) do
    Repo.delete(chat_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_message changes.

  ## Examples

      iex> change_chat_message(chat_message)
      %Ecto.Changeset{data: %ChatMessage{}}

  """
  def change_chat_message(%ChatMessage{} = chat_message, attrs \\ %{}) do
    ChatMessage.changeset(chat_message, attrs)
  end

  @doc """
  Gets unread message count from latest message ID sent in.
  """
  def get_unread_group_message_count(message_id) do
    # TODO: replace with a better query
    message = get_chat_message!(message_id)

    from(m in ChatMessage,
      select: count(),
      where:
        m.inserted_at >= ^message.inserted_at and m.id != ^message.id and
          m.group_id == ^message.group_id
    )
    |> Repo.one()
  end

  @doc """
  Gets previous messages with a limit.
  """
  def get_previous_messages(message_id, limit) do
    # TODO: replace with a better query
    message = get_chat_message!(message_id)

    from(m in ChatMessage,
      order_by: [desc: m.inserted_at],
      where:
        m.inserted_at <= ^message.inserted_at and m.id != ^message.id and
          m.group_id == ^message.group_id,
      limit: ^limit,
      preload: [:user, reply_to_message: :user]
    )
    |> Repo.all()
  end
end
