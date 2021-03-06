defmodule OmegaBraveraWeb.Api.Resolvers.Groups do
  alias OmegaBravera.Groups
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_partner_locations(_root, _args, _context),
    do: {:ok, Groups.list_partner_locations()}

  def list_partner_locations(_root, %{coordinate: %{longitude: long, latitude: lat}}, _context) do
    {:ok,
     %{
       partner_locations: Groups.list_partner_locations(long, lat),
       loaded_longitude: Decimal.from_float(long),
       loaded_latitude: Decimal.from_float(lat)
     }}
  end

  def list_partner_locations(_root, %{coordinate: nil}, %{
        context: %{current_user: %{location_id: location_id}}
      }) do
    %{geom: %{coordinates: {long, lat}}} = OmegaBravera.Locations.get_location!(location_id)

    {:ok,
     %{
       partner_locations: Groups.list_partner_locations(long, lat),
       loaded_longitude: Decimal.from_float(long),
       loaded_latitude: Decimal.from_float(lat)
     }}
  end

  def vote_partner(_root, %{partner_id: partner_id}, %{context: %{current_user: %{id: user_id}}}) do
    case Groups.create_partner_vote(%{partner_id: partner_id, user_id: user_id}) do
      {:ok, _vote} ->
        votes = Groups.get_partner_votes(partner_id)
        {:ok, votes}

      {:error, changeset} ->
        {:error,
         message: "Could not vote for partner", details: Helpers.transform_errors(changeset)}
    end
  end

  def get_partner(_root, %{partner_id: partner_id}, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Groups.get_partner_with_membership!(partner_id, user_id)}

  def get_partners(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Groups.list_partners_with_membership(user_id)}

  def get_partners_paginated(_root, args, %{context: %{current_user: %{id: user_id}}}),
    do: Groups.list_partners_with_membership_paginated(user_id, args)

  def search_groups_paginated(_root, %{global: global} = args, %{
        context: %{current_user: %{id: user_id, location_id: location_id}}
      }),
      do:
        Groups.search_groups_paginated(
          user_id,
          Map.get(args, :keyword),
          global,
          location_id,
          args,
          Map.get(args, :my_group)
        )

  def list_joined_partners(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Groups.list_joined_partners(user_id)}

  def join_partner(_root, %{partner_id: partner_id} = args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    int_partner_id = String.to_integer(partner_id)

    with %{id: ^int_partner_id} <-
           Groups.get_partner_with_password(int_partner_id, Map.get(args, :password)),
         {:ok, _} <- Groups.join_partner(partner_id, user_id) do
      {:ok, Groups.get_partner_with_membership!(partner_id, user_id)}
    else
      result ->
        case result do
          nil ->
            {:error, message: "Password incorrect."}

          {:error, :email_restricted} ->
            {:error, message: "This group is restricted to specific users."}

          {:error,
           %{
             errors: [
               user_id:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "partner_members_user_id_partner_id_index"
                  ]}
             ]
           }} ->
            {:error, message: "You have already joined this group."}
        end
    end
  end

  def leave_group(_root, %{group_id: group_id}, %{context: %{current_user: %{id: user_id}}}) do
    member = Groups.get_group_member_by_group_id_user_id(group_id, user_id)

    case Groups.delete_partner_member(member) do
      {:ok, _member} ->
        {:ok, Groups.get_partner_with_membership!(group_id, user_id)}

      error_tuple ->
        error_tuple
    end
  end
end
