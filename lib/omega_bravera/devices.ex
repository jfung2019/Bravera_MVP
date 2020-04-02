defmodule OmegaBravera.Devices do
  @moduledoc """
  The Devices context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo
  alias Ecto.Multi

  alias OmegaBravera.Devices.Device

  @doc """
  Returns the list of devices.

  ## Examples

      iex> list_devices()
      [%Device{}, ...]

  """
  def list_devices do
    Repo.all(Device)
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device!(123)
      %Device{}

      iex> get_device!(456)
      ** (Ecto.NoResultsError)

  """
  def get_device!(id), do: Repo.get!(Device, id)

  def get_device_by_uuid(uuid) do
    from(
      d in Device,
      where: d.uuid == ^uuid and d.active == true
    )
    |> Repo.one()
  end

  def get_active_device_by_user_id(user_id) do
    from(
      d in Device,
      where: d.user_id == ^user_id and d.active == true
    )
    |> Repo.one()
  end

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_device(%{active: true, user_id: user_id, uuid: uuid} = attrs) do
    Multi.new()
    |> Multi.run(:deactivate_devices, fn repo, _changes ->
      deactivate_all_devices(user_id, repo)
    end)
    |> Multi.run(:create_or_update_device, fn repo, _changes ->
      case find_device(user_id, uuid, repo) do
        %Device{} = device ->
          update_device(device, attrs, repo)

        nil ->
          do_create_device(attrs, repo)
      end
    end)
    |> Repo.transaction()
  end

  def create_device(%{active: false} = attrs) do
    Multi.new()
    |> Multi.run(:create_device, fn _repo, _changes -> do_create_device(attrs) end)
    |> Repo.transaction()
  end

  def deactivate_all_devices(user_id, repo \\ Repo) do
    {count, nil} =
      from(d in Device, where: d.user_id == ^user_id)
      |> repo.update_all(set: [active: false])

    {:ok, count}
  end

  defp do_create_device(attrs, repo \\ Repo) do
    %Device{}
    |> Device.changeset(attrs)
    |> repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_device(%Device{} = device, attrs, repo \\ Repo) do
    device
    |> Device.changeset(attrs)
    |> repo.update()
  end

  @doc """
  Deletes a Device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking device changes.

  ## Examples

      iex> change_device(device)
      %Ecto.Changeset{source: %Device{}}

  """
  def change_device(%Device{} = device) do
    Device.changeset(device, %{})
  end

  @doc """
  Finds a device by both user and the UUID of their device.
  """
  def find_device(user_id, uuid, repo \\ Repo) do
    from(d in Device, where: d.user_id == ^user_id and d.uuid == ^uuid)
    |> repo.one()
  end
end
