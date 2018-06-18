defmodule OmegaBraveraWeb.StravaView do
  use OmegaBraveraWeb, :view

  def render("hub_challenge.json", %{hub_challenge: hub_challenge}) do
    %{"hub.challenge" => hub_challenge}
  end

  def render("webhook_callback.json", %{status: status}) do
    %{"status" => status}
  end
end
