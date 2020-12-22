defmodule OmegaBravera.Kaffy.BraveraExt do
  def stylesheets(_conn) do
    [
      {:safe, ~s(<link rel="stylesheet" href="/css/kaffy.css" />)}
    ]
  end
end
