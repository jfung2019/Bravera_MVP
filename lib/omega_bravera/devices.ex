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

  def create_device(%{active: true, user_id: user_id} = attrs) do
    Multi.new()
    |> Multi.run(:deactivate_devices, fn _repo, _changes -> deactivate_all_devices(user_id) end)
    |> Multi.run(:create_device, fn _repo, _changes -> do_create_device(attrs) end)
    |> Repo.transaction()
  end

  def create_device(%{active: false} = attrs) do
    Multi.new()
    |> Multi.run(:create_device, fn _repo, _changes -> do_create_device(attrs) end)
    |> Repo.transaction()
  end

  def deactivate_all_devices(user_id) do
    {count, nil} =
      from(d in Device, where: d.user_id == ^user_id)
      |> Repo.update_all(set: [active: false])

    {:ok, count}
  end

  defp do_create_device(attrs) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
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
end