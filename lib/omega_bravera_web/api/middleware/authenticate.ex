defmodule OmegaBraveraWeb.Api.Middleware.Authenticate do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{current_user: %{}} ->
        resolution
      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "not_authorized"})
    end
  end
end