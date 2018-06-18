defmodule OmegaBraveraWeb.ViewHelpers do
  def logged_in?(conn) do
    user = Guardian.Plug.current_resource(conn)
    if user !== nil, do: true
  end

  def has_tracker?(conn) do
    user = Guardian.Plug.current_resource(conn)
    if user !== nil do
      %{strava: strava} = user
      if strava !== nil, do: true
    end
  end
end
