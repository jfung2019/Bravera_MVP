defmodule OmegaBraveraWeb.Api.Resolvers.Partners do
  alias OmegaBravera.Partners
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_partner_locations(_root, _args, _context) do
    {:ok, Partners.list_partner_locations()}
  end

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
end
