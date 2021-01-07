defmodule OmegaBraveraWeb.AdminPanelOrganizationMemberView do
  use OmegaBraveraWeb, :view

  def generate_organizations(organizations), do: Enum.map(organizations, &{"#{&1.name}", &1.id})
end
