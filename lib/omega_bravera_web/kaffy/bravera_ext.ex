defmodule OmegaBraveraWeb.Kaffy.BraveraExt do
  def stylesheets(_conn) do
    [
      {:safe,
       ~s(<link rel="stylesheet" href="/css/kaffy.css" /> <link rel="shortcut icon" href="/favicon.ico" />)}
    ]
  end
end
