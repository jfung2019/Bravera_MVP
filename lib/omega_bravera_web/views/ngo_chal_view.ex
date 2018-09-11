defmodule OmegaBraveraWeb.NGOChalView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.Challenges.NGOChal

  def active_challenge?(%NGOChal{} = challenge) do
    challenge.status == "active"
  end
end
