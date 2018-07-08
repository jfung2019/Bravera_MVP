defmodule OmegaBraveraWeb.DonationController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Money
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Challenges
  alias OmegaBravera.Accounts
  alias OmegaBravera.Stripe
  alias OmegaBravera.StripeHelpers

  def index(conn, _params) do
    donations = Money.list_donations()
    render(conn, "index.html", donations: donations)
  end

  def new(conn, _params) do
    changeset = Money.change_donation(%Donation{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"donation" => donation_params, "ngo_chal_slug" => ngo_chal_slug}) do
  # TODO re-implement the SECURED/PLEDGED LOGIC
  # TODO Do all the form validations for this
  # TODO simplify kickstarter logic since all have kickstarter now

  IO.inspect(donation_params)
  IO.inspect(ngo_chal_slug)

    # TODO change milestone logic to programmatically generate milestones based on one value
    milestones = create_milestone_map(donation_params)

    nc = Challenges.get_ngo_chal_by_slug(ngo_chal_slug)

    %{ngo_id: ngo_id, id: ngo_chal_id} = nc

    %{"str_src" => str_src, "currency" => currency, "email" => email} = donation_params

    ngo = Fundraisers.get_ngo!(ngo_id)

    user =
      cond do
        Guardian.Plug.current_resource(conn) ->
          Guardian.Plug.current_resource(conn)
        true ->
          Accounts.insert_or_return_email_user(email)
      end

    %{id: user_id} = user

    kickstarter = donation_params["kickstarter"]

    # TODO examine the following code, Do we just need customers, not SRCs?
    # Do we just create customers every time rather than managing sources?

    str_customer =
      case Stripe.get_user_str_customer(user_id) do
        nil ->
          StripeHelpers.create_stripe_customer(email, str_src, user_id)
        customer ->
          customer
      end

    %{id: str_customer_id, cus_id: cus_id} = str_customer

    rel_params = %{user_id: user_id, ngo_chal_id: ngo_chal_id, ngo_id: ngo_id}

    cond do
      kickstarter ->
        charge_params = %{
          "amount" => kickstarter,
          "currency" => currency,
          "customer" => cus_id,
          "source" => str_src,
        }

        case StripeHelpers.charge_stripe_customer(ngo, charge_params) do
          {:ok, response} ->
            %{body: response_body} = response
            body = Poison.decode!(response_body)

            cond do
              body["source"] ->
                case Money.create_donations(rel_params, milestones, kickstarter, currency, str_src) do
                  {:ok, response} ->
                    conn
                    |> put_flash(:info, "Donation created successfully.")
                    |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_id, ngo_chal_id))

                  {:error, %Ecto.Changeset{} = changeset} ->
                    render(conn, :new, changeset: changeset)
                end

              body["error"] ->
                render(conn, :new)
            end

          :error ->
            render(conn, :new)
        end

      true ->
        case Money.create_donations(rel_params, milestones, currency, str_src) do
          {:ok, response} ->
            conn
            |> put_flash(:info, "Donation created successfully.")
            |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_id, ngo_chal_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :show, changeset: changeset)
      end
    end
  end

  def show(conn, %{"id" => id}) do
    donation = Money.get_donation!(id)
    render(conn, "show.html", donation: donation)
  end

  def edit(conn, %{"id" => id}) do
    donation = Money.get_donation!(id)
    changeset = Money.change_donation(donation)
    render(conn, "edit.html", donation: donation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "donation" => donation_params}) do
    donation = Money.get_donation!(id)

    case Money.update_donation(donation, donation_params) do
      {:ok, donation} ->
        conn
        |> put_flash(:info, "Donation updated successfully.")
        |> redirect(to: user_path(conn, :donations, donation))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", donation: donation, changeset: changeset)
    end
  end

  defp create_milestone_map(donation_params) do
    cond do
      donation_params["milestone_6"] ->
        %{6 => donation_params["milestone_6"],5 => donation_params["milestone_5"],4 => donation_params["milestone_4"],3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_5"] ->
        %{5 => donation_params["milestone_5"],4 => donation_params["milestone_4"],3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_4"] ->
        %{4 => donation_params["milestone_4"],3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_3"] ->
        %{3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_2"] ->
        %{2 => donation_params["milestone_2"], 1 => donation_params["milestone_1"]}
      donation_params["milestone_1"] ->
        %{1 => donation_params["milestone_1"]}
    end
  end

end
