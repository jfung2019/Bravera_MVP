defmodule OmegaBravera.Accounts.SlackNotifier do
  alias OmegaBravera.Accounts.PartnerUser

  @doc """
  send message to slack channel to notify new partner_user
  """
  @spec notify_new_partner_user(PartnerUser.t()) ::
          {:ok, HTTPoison.Response.t()}
          | {:error, HTTPoison.Error.t()}
  def notify_new_partner_user(%PartnerUser{} = partner_user) do
    payload =
      %{
        text: get_partner_user_info(partner_user)
      }
      |> Jason.encode!()

    HTTPoison.post(Application.get_env(:omega_bravera, :slack_sales_channel), payload, [
      {"Content-Type", "application/json"}
    ])
  end

  @spec get_partner_user_info(PartnerUser.t()) :: String.t()
  defp get_partner_user_info(partner_user) do
    """
    New customer admin signed up.
    organization: #{Enum.at(partner_user.organizations, 0).name}
    firstname: #{partner_user.first_name}
    lastname: #{partner_user.last_name}
    contact number: #{partner_user.contact_number}
    location: #{partner_user.location.name_en}
    username: #{partner_user.username}
    email: #{partner_user.email}
    business website: #{Enum.at(partner_user.organizations, 0).business_website}
    """
    |> String.trim()
  end
end
