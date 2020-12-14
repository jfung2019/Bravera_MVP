defmodule OmegaBraveraWeb.ErrorView do
  use OmegaBraveraWeb, :view
  require Logger

  def render("500.json", assigns) do
    Logger.error("Error rendered: #{inspect(assigns)}")
    %{error: "Server error"}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, _assigns),
    do: Phoenix.Controller.status_message_from_template(template)
end
