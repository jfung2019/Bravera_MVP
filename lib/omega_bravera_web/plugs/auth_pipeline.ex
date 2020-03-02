defmodule OmegaBravera.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :omega_bravera,
    module: OmegaBravera.Guardian,
    error_handler: OmegaBravera.AuthErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end
