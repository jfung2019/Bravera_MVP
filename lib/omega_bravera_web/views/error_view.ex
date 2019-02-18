defmodule OmegaBraveraWeb.ErrorView do
  use OmegaBraveraWeb, :view

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end

  def render("500.json", _assigns), do: %{error: "Server error"}
end
