# defmodule OmegaBraveraWeb.NGOChalController do
#   use OmegaBraveraWeb, :controller
#
#   alias OmegaBravera.{Accounts, Challenges, Fundraisers, Money}
#   alias OmegaBravera.Challenges.NGOChal
#   alias OmegaBravera.Money.Donation
#   alias OmegaBravera.Slugify
#
#   def index(conn, _params) do
#     ngo_chals = Challenges.list_ngo_chals()
#     render(conn, "index.html", ngo_chals: ngo_chals)
#   end
#
#   def new(conn, _params) do
#     changeset = Challenges.change_ngo_chal(%NGOChal{})
#     render(conn, "new.html", changeset: changeset)
#   end
#
#   def create(conn, %{"ngo_id" => ngo_id, "ngo_chal" => ngo_chal_params}) do
#
#     current_user = Guardian.Plug.current_resource(conn)
#
#     IO.inspect(current_user)
#
#     %{id: user_id, firstname: firstname} = current_user
#
#     ngo = String.to_integer(ngo_id)
#
#     slug = Slugify.gen_random_slug(firstname)
#
#     case Challenges.insert_ngo_chal(ngo_chal_params, ngo, user_id, slug) do
#       {:ok, ngo_chal} ->
#         # TODO put the social share link in the put_flash?!
#         conn
#         |> put_flash(:info, "Success! You have registered for the challenge!")
#         |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo, ngo_chal))
#
#       {:error, %Ecto.Changeset{} = changeset} ->
#         render(conn, "new.html", changeset: changeset)
#     end
#   end
#
#   def show(conn, %{"id" => id}) do
#     # TODO optimize all of the maps being passed thru into one map
#
#     ngo_chal = Challenges.get_ngo_chal!(id)
#     IO.inspect(ngo_chal)
#     %{user_id: user_id, ngo_id: ngo_id} = ngo_chal
#
#     user = Accounts.get_user!(user_id)
#     ngo = Fundraisers.get_ngo!(ngo_id)
#     strava = Accounts.get_user_strava(user_id)
#     changeset = Money.change_donation(%Donation{})
#
#     render(conn, "show.html", ngo_chal: ngo_chal, user: user, ngo: ngo, strava: strava, changeset: changeset)
#   end
#
#   def edit(conn, %{"id" => id}) do
#     ngo_chal = Challenges.get_ngo_chal!(id)
#     changeset = Challenges.change_ngo_chal(ngo_chal)
#     render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
#   end
#
#   def update(conn, %{"id" => id, "ngo_chal" => ngo_chal_params}) do
#     ngo_chal = Challenges.get_ngo_chal!(id)
#
#     case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
#       {:ok, ngo_chal} ->
#         conn
#         |> put_flash(:info, "Ngo chal updated successfully.")
#         |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_chal))
#       {:error, %Ecto.Changeset{} = changeset} ->
#         render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
#     end
#   end
#
#   def delete(conn, %{"id" => id}) do
#     ngo_chal = Challenges.get_ngo_chal!(id)
#     {:ok, _ngo_chal} = Challenges.delete_ngo_chal(ngo_chal)
#
#     conn
#     |> put_flash(:info, "Ngo chal deleted successfully.")
#     |> redirect(to: ngo_ngo_chal_path(conn, :index))
#   end
# end
