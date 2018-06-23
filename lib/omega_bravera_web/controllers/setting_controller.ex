defmodule OmegaBraveraWeb.SettingController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.Setting

  def show(conn, %{"id" => id}) do
    setting = Accounts.get_setting!(id)
    render(conn, "show.html", setting: setting)
  end

  def edit(conn, %{"id" => id}) do
    setting = Accounts.get_setting!(id)
    changeset = Accounts.change_setting(setting)
    render(conn, "edit.html", setting: setting, changeset: changeset)
  end

  def update(conn, %{"id" => id, "setting" => setting_params}) do
    setting = Accounts.get_setting!(id)

    case Accounts.update_setting(setting, setting_params) do
      {:ok, setting} ->
        conn
        |> put_flash(:info, "Setting updated successfully.")
        |> redirect(to: setting_path(conn, :show, setting))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", setting: setting, changeset: changeset)
    end
  end
end
