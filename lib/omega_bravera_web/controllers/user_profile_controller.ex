defmodule OmegaBraveraWeb.UserProfileController do
  use OmegaBraveraWeb, :controller

  import Mogrify

  alias OmegaBravera.{Challenges, Accounts.User, Repo, Offers, Points}

  def show(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        redirect(conn, to: "/404")

      user ->
        distance = Challenges.get_total_distance_by_user(user.id)
        points = Points.get_user_points(user.id)

        render(
          conn,
          "show.html",
          user: user,
          num_of_activities: Challenges.get_number_of_activities_by_user(user.id),
          total_distance: distance,
          total_points: points,
          solo_challenges: Challenges.get_user_solo_ngo_chals(user.id),
          team_challenges: Challenges.get_user_team_ngo_chals(user.id),
          offer_challenges: Offers.get_user_offer_challenges(user.id, [:offer, :offer_redeems]),
          teams_memberships: Challenges.get_user_team_membership(user.id),
          changeset: User.changeset(user, %{})
        )
    end
  end

  def update_profile_picture(conn, %{"user" => %{"profile_picture" => image_params}}) do
    file_uuid = Ecto.UUID.generate()
    unique_filename = "#{file_uuid}-#{Path.extname(image_params.filename)}"
    user = Guardian.Plug.current_resource(conn)

    bucket_name = Application.get_env(:omega_bravera, :images_bucket_name)

    if not is_nil(user.profile_picture) do
      filename = URI.parse(user.profile_picture).path

      bucket_name
      |> ExAws.S3.delete_object(filename)
      |> ExAws.request()
    end

    resized_image =
      image_params.path
      |> open()
      |> resize("600x600")
      |> save(in_place: true)

    resized_image.path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket_name, "profile_pictures/#{unique_filename}", acl: :public_read)
    |> ExAws.request!()

    changeset =
      User.update_profile_picture_changeset(user, %{
        profile_picture:
          "https://#{bucket_name}.s3.amazonaws.com/profile_pictures/#{unique_filename}"
      })

    case Repo.update(changeset) do
      {:ok, _upload} ->
        conn
        |> put_flash(:info, "Profile picture uploaded successfully!")
        |> redirect(to: Routes.user_profile_path(conn, :show))

      {:error, changeset} ->
        render(conn, "show.html", changeset: changeset)
    end
  end
end
