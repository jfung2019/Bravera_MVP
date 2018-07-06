# Errors

I dunno why tf I got this when I tried to register an ngo_chal participant, it worked when I tried again:
```elixir
%OmegaBravera.Accounts.User{
  __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  credential: #Ecto.Association.NotLoaded<association :credential is not loaded>,
  donations: #Ecto.Association.NotLoaded<association :donations is not loaded>,
  email: "njwest9@gmail.com",
  firstname: "Nick",
  id: 1,
  inserted_at: ~N[2018-06-18 14:31:33.419773],
  lastname: "West",
  ngo_chals: [],
  ngos: #Ecto.Association.NotLoaded<association :ngos is not loaded>,
  setting: #Ecto.Association.NotLoaded<association :setting is not loaded>,
  str_customers: #Ecto.Association.NotLoaded<association :str_customers is not loaded>,
  strava: %OmegaBravera.Trackers.Strava{
    __meta__: #Ecto.Schema.Metadata<:loaded, "stravas">,
    athlete_id: 28004310,
    email: "njwest9@gmail.com",
    firstname: "Nick",
    id: 1,
    inserted_at: ~N[2018-06-30 17:00:39.820433],
    lastname: "West",
    token: "feeda69610fc96637ccd5bef8a512ed66592834d",
    updated_at: ~N[2018-06-30 17:00:39.820442],
    user: #Ecto.Association.NotLoaded<association :user is not loaded>,
    user_id: 1
  },
  updated_at: ~N[2018-06-18 14:31:33.419783]
}
[debug] QUERY OK db=0.1ms
begin []
[debug] QUERY ERROR db=35.3ms
INSERT INTO "ngo_chals" ("activity","distance_covered","distance_target","duration","milestones","money_target","ngo_id","slug","start_date","status","total_pledged","total_secured","user_id","inserted_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING "id" ["Run", #Decimal<0>, #Decimal<5000>, 30, 3, #Decimal<2000>, 1, "nick-329", {{2013, 1, 1}, {0, 0, 0, 0}}, "Active", #Decimal<0>, #Decimal<0>, 1, {{2018, 7, 6}, {10, 19, 6, 751768}}, {{2018, 7, 6}, {10, 19, 6, 751778}}]
[debug] QUERY OK db=0.2ms
rollback []
[info] Sent 500 in 95ms
[error] #PID<0.4039.0> running OmegaBraveraWeb.Endpoint (cowboy_protocol) terminated
Server: localhost:4000 (http)
Request: POST /1
** (exit) an exception was raised:
    ** (Ecto.ConstraintError) constraint error when attempting to insert struct:

    * unique: ngo_chals_pkey

If you would like to convert this constraint into an error, please
call unique_constraint/3 in your changeset and define the proper
constraint name. The changeset has not defined any constraint.

        (ecto) lib/ecto/repo/schema.ex:574: anonymous fn/4 in Ecto.Repo.Schema.constraints_to_errors/3
        (elixir) lib/enum.ex:1294: Enum."-map/2-lists^map/1-0-"/2
        (ecto) lib/ecto/repo/schema.ex:559: Ecto.Repo.Schema.constraints_to_errors/3
        (ecto) lib/ecto/repo/schema.ex:222: anonymous fn/14 in Ecto.Repo.Schema.do_insert/4
        (ecto) lib/ecto/repo/schema.ex:774: anonymous fn/3 in Ecto.Repo.Schema.wrap_in_transaction/6
        (ecto) lib/ecto/adapters/sql.ex:576: anonymous fn/3 in Ecto.Adapters.SQL.do_transaction/3
        (db_connection) lib/db_connection.ex:1283: DBConnection.transaction_run/4
        (db_connection) lib/db_connection.ex:1207: DBConnection.run_begin/3
        (db_connection) lib/db_connection.ex:798: DBConnection.transaction/3
        (omega_bravera) lib/omega_bravera_web/controllers/ngo_chal_controller.ex:31: OmegaBraveraWeb.NGOChalController.create/2
        (omega_bravera) lib/omega_bravera_web/controllers/ngo_chal_controller.ex:1: OmegaBraveraWeb.NGOChalController.action/2
        (omega_bravera) lib/omega_bravera_web/controllers/ngo_chal_controller.ex:1: OmegaBraveraWeb.NGOChalController.phoenix_controller_pipeline/2
        (omega_bravera) lib/omega_bravera_web/endpoint.ex:1: OmegaBraveraWeb.Endpoint.instrument/4
        (phoenix) lib/phoenix/router.ex:278: Phoenix.Router.__call__/1
        (omega_bravera) lib/omega_bravera_web/endpoint.ex:1: OmegaBraveraWeb.Endpoint.plug_builder_call/2
        (omega_bravera) lib/plug/debugger.ex:102: OmegaBraveraWeb.Endpoint."call (overridable 3)"/2
        (omega_bravera) lib/omega_bravera_web/endpoint.ex:1: OmegaBraveraWeb.Endpoint.call/2
        (plug) lib/plug/adapters/cowboy/handler.ex:16: Plug.Adapters.Cowboy.Handler.upgrade/4
        (cowboy) /Users/nick/Desktop/omega_bravera/deps/cowboy/src/cowboy_protocol.erl:442: :cowboy_protocol.execute/4
[debug] Live reload: lib/omega_bravera_web/templates/ngo/index.html.eex
```

Worked after :\
