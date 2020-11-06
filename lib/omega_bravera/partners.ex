defmodule OmegaBravera.Partners do
  @moduledoc """
  The Partners context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Partners.{Partner, Member, OfferPartner}

  @doc """
  Returns the list of partner.

  ## Examples

      iex> list_partner()
      [%Partner{}, ...]

  """
  def list_partner do
    Repo.all(Partner)
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
    |> Repo.preload([:location, :offers])
  end

  @doc """
  Get partners a partner and shows whether that user is a member
  of that partner.
  """
  def get_partner_with_membership!(id, user_id) do
    from(p in Partner,
      distinct: true,
      left_join: o in assoc(p, :offers),
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

  def list_partners_with_membership(user_id) do
    from(p in Partner,
      distinct: true,
      left_join: o in assoc(p, :offers),
      left_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      where: p.live == true,
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
    |> Repo.all()
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

  @doc """
  Updates a partner.

  ## Examples

      iex> update_partner(partner, %{field: new_value})
      {:ok, %Partner{}}

      iex> update_partner(partner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_partner(%Partner{} = partner, attrs) do
    partner
    |> Partner.changeset(attrs)
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

  alias OmegaBravera.Partners.PartnerLocation

  @doc """
  Returns the list of partner_locations.

  ## Examples

      iex> list_partner_locations()
      [%PartnerLocation{}, ...]

  """
  def list_partner_locations do
    from(l in PartnerLocation, left_join: p in assoc(l, :partner), where: p.live == true)
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

  alias OmegaBravera.Partners.PartnerVote

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
    %Member{}
    |> Member.changeset(%{user_id: user_id, partner_id: partner_id})
    |> Repo.insert()
  end

  @doc """
  Lists all members from a partner ID.
  """
  def list_partner_members(partner_id) do
    from(m in Member, where: m.partner_id == ^partner_id, preload: [:user])
    |> Repo.all()
  end

  @doc """
  Gets a partner member by their ID.
  """
  def get_partner_member!(member_id), do: Repo.get!(Member, member_id)

  @doc """
  Delete partner member.
  """
  def delete_partner_member(member), do: Repo.delete(member)

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

  @doc """
  Get the partners joined by the user.
  """
  def list_joined_partners(user_id) do
    from(p in Partner,
      left_join: m in assoc(p, :members),
      where: m.user_id == ^user_id and p.live == true
    )
    |> Repo.all()
  end

  @doc """
  Allows a partner to be joined to an offer.
  """
  def create_offer_partner(attrs) do
    %OfferPartner{}
    |> OfferPartner.changeset(attrs)
    |> Repo.insert()
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
end
