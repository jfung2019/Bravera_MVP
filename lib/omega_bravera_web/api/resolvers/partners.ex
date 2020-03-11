defmodule OmegaBraveraWeb.Api.Resolvers.Partners do
  alias OmegaBravera.Partners

  def latest_partner_locations(_root, _args, _context) do
    {:ok, Partners.list_partner_locations()}
  end
end
