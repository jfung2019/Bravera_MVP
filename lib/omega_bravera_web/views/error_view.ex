defmodule OmegaBraveraWeb.ErrorView do
  use OmegaBraveraWeb, :view

  def render("500.json", _assigns), do: %{error: "Server error"}

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, _assigns),
    do: Phoenix.Controller.status_message_from_template(template)
end
