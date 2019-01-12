defmodule OmegaBraveraWeb.AdminPanelNGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Fundraisers, Slugify, Challenges}
  alias OmegaBravera.Fundraisers.NGO

  use Timex

  plug(:assign_available_options when action in [:edit, :new])

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos_preload()
    render(conn, "index.html", ngos: ngos)
  end

  def show(conn, %{"slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug)
    render(conn, "show.html", ngo: ngo)
  end

  def new(conn, _params) do
    users = Accounts.list_users()
    changeset = Fundraisers.change_ngo(%NGO{})
    conn |> render("new.html", changeset: changeset, users: users)
  end

  def create(conn, %{"ngo" => ngo_params}) do
    sluggified_ngo_name = Slugify.gen_slug(ngo_params["name"])

    ngo_params =
      ngo_params
      |> Map.put("slug", sluggified_ngo_name)

    case Fundraisers.create_ngo(ngo_params) do
      {:ok, ngo} ->
        conn
        |> put_flash(:info, "NGO created successfully.")
        |> redirect(to: admin_panel_ngo_path(conn, :show, ngo))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users()

        conn
        |> assign_available_options(nil)
        |> render("new.html", changeset: changeset, users: users)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    ngo = slug |> Fundraisers.get_ngo_by_slug_with_hk_time()
    users = Accounts.list_users()
    changeset = ngo |> Fundraisers.change_ngo()
    render(conn, "edit.html", ngo: ngo, users: users, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "ngo" => ngo_params}) do
    ngo = slug |> Fundraisers.get_ngo_by_slug_with_hk_time()

    case Fundraisers.update_ngo(ngo, ngo_params) do
      {:ok, updated_ngo} ->
        # Update all pre_registration challenges' start date
        ngo.ngo_chals
        |> Enum.map(fn challenge ->
          if challenge.status == "pre_registration" do
            Challenges.update_ngo_chal(challenge, %{start_date: updated_ngo.launch_date})
          end
        end)

        conn
        |> put_flash(:info, "NGO updated successfully.")
        |> redirect(to: admin_panel_ngo_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users()

        conn
        |> assign_available_options(nil)
        |> render("edit.html", users: users, ngo: ngo, changeset: changeset)
    end
  end

  def statement(conn, %{"slug" => slug}) do
    ngo = Fundraisers.get_donations_for_ngo(slug)
    render(conn, "statement.html", ngo: ngo, layout: {OmegaBraveraWeb.LayoutView, "print.html"})
  end

  def export_statement(conn, %{"slug" => slug, "month" => month, "year" => year}) do
    {:ok, start_date} = Date.new(String.to_integer(year), String.to_integer(month), 1)
    start_datetime = Timex.to_datetime(start_date)
    end_datetime = Timex.shift(start_datetime, months: 1)
    csv_rows = Fundraisers.get_monthly_donations_for_ngo(slug, start_datetime, end_datetime)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"statement.csv\"")
    |> send_resp(200, csv_content(csv_rows))
  end

  defp csv_content(rows) do
    cols = [
      [
        "Challenge Name",
        "Transaction Reference",
        "Payment Date",
        "Participant",
        "Supporter Name",
        "Supporter Email",
        "Milestone",
        "Challenge Currency",
        "Donation Total",
        "Gateway Fee(3.4% + HKD 2.35)",
        "Bravera Fees(6%)",
        "Net Donation"
      ]
    ]

    (cols ++ rows)
    |> CSV.encode()
    |> Enum.to_list()
    |> to_string
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_currencies, Fundraisers.available_currencies())
    |> assign(:available_activities, Fundraisers.available_activities())
    |> assign(:available_distances, Fundraisers.available_distances())
    |> assign(:available_durations, Fundraisers.available_durations())
    |> assign(:available_challenge_type_options, Fundraisers.available_challenge_type_options())
  end
end
