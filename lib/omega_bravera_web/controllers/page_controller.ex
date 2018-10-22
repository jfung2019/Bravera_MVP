defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Challenges, Fundraisers}
  alias OmegaBravera.Accounts.AdminUser

  def notFound(conn, _params) do
    render(conn, "404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
  end

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->

        case user do
          %AdminUser{} ->
            redirect(conn, to: admin_user_page_path(conn, :index))

          _ ->
            %{id: user_id} = user

            active_chal = Challenges.get_one_user_active_chal(user_id)

            cond do
              active_chal !== nil ->
                %{slug: chal_slug, ngo_id: ngo_id} = active_chal

                ngo = Fundraisers.get_ngo!(ngo_id)

                %{slug: ngo_slug} = ngo

                redirect(conn, to: "/" <> ngo_slug <> "/" <> chal_slug)

              true ->
                redirect(conn, to: "/ngos")
            end

        end

      true ->
        render(conn, "index.html")
    end
  end

  def signup(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        %{id: user_id} = user

        active_chal = Challenges.get_one_user_active_chal(user_id)

        cond do
          active_chal !== nil ->
            %{slug: chal_slug, ngo_id: ngo_id} = active_chal

            ngo = Fundraisers.get_ngo!(ngo_id)

            %{slug: ngo_slug} = ngo

            redirect(conn, to: "/" <> ngo_slug <> "/" <> chal_slug)

          true ->
            redirect(conn, to: "/ngos")
        end

      true ->
        render(conn, "signup.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end

  def login(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        %{id: user_id} = user

        active_chal = Challenges.get_one_user_active_chal(user_id)

        cond do
          active_chal !== nil ->
            %{slug: chal_slug, ngo_id: ngo_id} = active_chal

            ngo = Fundraisers.get_ngo!(ngo_id)

            %{slug: ngo_slug} = ngo

            redirect(conn, to: "/" <> ngo_slug <> "/" <> chal_slug)

          true ->
            redirect(conn, to: "/ngos")
        end

      true ->
        render(conn, "login.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end
end
