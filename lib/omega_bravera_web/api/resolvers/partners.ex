defmodule OmegaBraveraWeb.Api.Resolvers.Partners do
  alias OmegaBravera.Partners
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_partner_locations(_root, _args, _context),
    do: {:ok, Partners.list_partner_locations()}

  def vote_partner(_root, %{partner_id: partner_id}, %{context: %{current_user: %{id: user_id}}}) do
    case Partners.create_partner_vote(%{partner_id: partner_id, user_id: user_id}) do
      {:ok, _vote} ->
        votes = Partners.get_partner_votes(partner_id)
        {:ok, votes}

      {:error, changeset} ->
        {:error,
         message: "Could not vote for partner", details: Helpers.transform_errors(changeset)}
    end
  end

  def get_partner(_root, %{partner_id: partner_id}, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Partners.get_partner_with_membership!(partner_id, user_id)}

  def get_partners(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Partners.list_partners_with_membership(user_id)}

  def list_joined_partners(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Partners.list_joined_partners(user_id)}

  def join_partner(_root, %{partner_id: partner_id} = args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    int_partner_id = String.to_integer(partner_id)

    with %{id: ^int_partner_id} <-
           Partners.get_partner_with_password(int_partner_id, Map.get(args, :password)),
         {:ok, _} <- Partners.join_partner(partner_id, user_id) do
      {:ok, Partners.get_partner_with_membership!(partner_id, user_id)}
    else
      nil ->
        {:error, message: "Password incorrect."}
    end
  end
end
