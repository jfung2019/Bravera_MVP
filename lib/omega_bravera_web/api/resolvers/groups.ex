defmodule OmegaBraveraWeb.Api.Resolvers.Groups do
  alias OmegaBravera.Groups
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_partner_locations(_root, _args, _context),
    do: {:ok, Groups.list_partner_locations()}

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

  def search_groups(_root, %{keyword: keyword, coordination: coordination}, %{
        context: %{current_user: %{id: user_id}}
      }),
      do: {:ok, Groups.search_groups(user_id, keyword, coordination)}

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
      nil ->
        {:error, message: "Password incorrect."}
    end
  end
end
