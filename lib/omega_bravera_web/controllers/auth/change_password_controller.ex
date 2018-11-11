defmodule OmegaBraveraWeb.ChangePasswordController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts

  def new(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user.credential == nil ->
        changeset = Accounts.change_credential(%Accounts.Credential{})
        render(conn, "new.html", changeset: changeset, user: user)
      user.credential != nil ->
        redirect(conn, to: change_password_path(conn, :edit, %{}))
    end
  end

  def create(conn, %{"credential" => credential_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.create_credential(user.id, credential_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password created successfully.")
        |> redirect(to: user_profile_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, user: user)
    end
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Accounts.change_credential(%Accounts.Credential{})
    render(conn, "edit.html", changeset: changeset, credential: user.credential, user: user)
  end

  def update(conn, %{"credential" => credential_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.update_credential(user.credential, credential_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: user_profile_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", credential: user.credential, changeset: changeset, user: user)
    end
  end
end
