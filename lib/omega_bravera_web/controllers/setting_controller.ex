defmodule OmegaBraveraWeb.SettingController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts

  plug(:assign_options when action in [:edit, :new, :update])

  def new(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user.setting == nil ->
        changeset = Accounts.change_setting(%Accounts.Setting{})
        render(conn, "new.html", changeset: changeset)

      user.setting != nil ->
        render(conn, "show.html", setting: user.setting)
    end
  end

  def create(conn, %{"setting" => settings_params}) do
    user = Guardian.Plug.current_resource(conn)

    changeset_params =
      Map.merge(settings_params, %{"user_id" => user.id}) |> calculate_weight_fraction()

    case Accounts.create_setting(changeset_params) do
      {:ok, _setting} ->
        conn
        |> put_flash(:info, "Settings created successfully.")
        |> redirect(to: setting_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user.setting == nil ->
        redirect(conn, to: setting_path(conn, :new))

      user.setting != nil ->
        render(conn, "show.html", setting: user.setting)
    end
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user.setting == nil ->
        redirect(conn, to: setting_path(conn, :new))

      user.setting != nil ->
        {weight, fraction} = split_fraction(user.setting)

        setting =
          user.setting
          |> Map.put(:weight, weight)
          |> Map.put(:weight_fraction, fraction)

        changeset = Accounts.change_setting(setting)
        render(conn, "edit.html", setting: setting, changeset: changeset)
    end
  end

  def update(conn, %{"setting" => setting_params}) do
    user = Guardian.Plug.current_resource(conn)
    setting_params = setting_params |> calculate_weight_fraction()

    case Accounts.update_setting(user.setting, setting_params) do
      {:ok, _setting} ->
        conn
        |> put_flash(:info, "Settings updated successfully.")
        |> redirect(to: setting_path(conn, :show, %{}))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", setting: user.setting, changeset: changeset)
    end
  end

  defp assign_options(conn, _opts) do
    conn
    |> assign(:gender_options, Accounts.Setting.gender_options())
    |> assign(:weight_list, Accounts.Setting.weight_list())
    |> assign(:weight_fraction_list, Accounts.Setting.weight_fraction_list())
  end

  defp calculate_weight_fraction(params) do
    {weight, _} = Map.get(params, "weight") |> Integer.parse()
    {fraction, _} = Map.get(params, "weight_fraction") |> Float.parse()

    params
    |> Map.put("weight", weight + fraction)
  end

  defp split_fraction(params) do
    weight = Map.get(params, :weight)

    cond do
      weight != nil ->
        {whole, decimal} = weight |> Decimal.div_rem(1)

        {Decimal.to_string(whole), Decimal.to_string(decimal)}

      weight == nil ->
        {"", ""}
    end
  end
end
