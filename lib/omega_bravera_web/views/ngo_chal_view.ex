defmodule OmegaBraveraWeb.NGOChalView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{
    Challenges.NGOChal,
    Accounts.User,
    Accounts.Donor,
    Fundraisers.NGO,
    Challenges.TeamInvitations
  }

  def open_delayed_modal(%NGOChal{ngo: %NGO{one_off_donations: one_off_donations}})
      when one_off_donations == false,
      do: "open-delayed-donation-modal"

  def open_delayed_modal(_), do: ""

  def immediate_donation?(%NGOChal{ngo: %NGO{one_off_donations: one_off_donations}}),
    do: one_off_donations

  def user_full_name(%User{} = user), do: User.full_name(user)
  def user_full_name(%Donor{} = donor), do: Donor.full_name(donor)

  def user_profile_pic(nil), do: ""

  def active_challenge?(%NGOChal{status: "active"}), do: true
  def active_challenge?(%NGOChal{}), do: false

  def pre_registration_challenge?(%NGOChal{status: "pre_registration"}), do: true
  def pre_registration_challenge?(%NGOChal{}), do: false

  def challenger_not_self_donated?(%NGOChal{user_id: user_id, self_donated: false}, %User{
        id: user_id
      }),
      do: true

  def challenger_not_self_donated?(_, _), do: false

  def render_percentage(target, current, previous \\ 0)

  def render_percentage(%Decimal{} = target, current, previous) do
    render_percentage(Decimal.to_float(target), current, previous)
  end

  def render_percentage(target, current, %Decimal{} = previous) do
    render_percentage(target, current, Decimal.to_float(previous))
  end

  def render_percentage(target, %Decimal{} = current, previous) do
    render_percentage(target, Decimal.to_float(current), previous)
  end

  def render_percentage(_target, current, previous) when current <= previous, do: 0
  def render_percentage(_target, 0, _previous), do: 0
  def render_percentage(target, current, 0) when current >= target, do: 100
  def render_percentage(target, current, 0), do: current / target * 100
  def render_percentage(target, current, _previous) when current >= target, do: 100

  def render_percentage(target, current, previous) when previous > 0 do
    ((current - previous) / target * 100)
    |> Float.round(2)
  end

  def render_progress_bar(
        target,
        previous_target,
        %{default_currency: currency, distance_covered: distance},
        total
      ) do
    percentage = render_percentage(target, distance, previous_target)

    {label_class, total_class} =
      if percentage >= 100 do
        {"text-bravera text-500", "float-right text-success"}
      else
        {"milestone-label", "float-right"}
      end

    [
      content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1", style: "text-align: left;") do
        [
          content_tag(:span, "#{target}km", class: label_class),
          content_tag(:span, class: "text-secondary") do
            content_tag(:strong, "#{currency_to_symbol(currency)}#{total || 0}",
              class: total_class
            )
          end
        ]
      end,
      content_tag(:div, "", style: "clear: both;"),
      content_tag(:div, class: "progress milestone-chal-progress mb-2") do
        content_tag(:div, "",
          class: "progress-bar bg-bravera",
          style: "width: #{percentage}%",
          role: "progressbar",
          "aria-valuenow": "",
          "aria-valuemin": "0",
          "aria-valuemax": ""
        )
      end
    ]
  end

  def render_progress_bar(%Decimal{} = distance_covered, distance_target) do
    percentage = render_percentage_exceed(distance_covered, distance_target)

    {label_class, total_class} =
      if percentage >= 100 do
        {"text-bravera text-500", "float-right text-success"}
      else
        {"milestone-label", "float-right"}
      end

    [
      content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1", style: "text-align: left;") do
        content_tag(:div, class: "d-flex justify-content-between bd-highlight mb-3") do
          [
            content_tag(:span, "0", class: "p-2 " <> label_class),
            content_tag(:div, class: "progress km-chal-progress") do
              content_tag(:div, "",
                class: "progress-bar bg-bravera",
                style: "width: #{percentage}%",
                role: "progressbar",
                "aria-valuenow": "",
                "aria-valuemin": "0",
                "aria-valuemax": ""
              )
            end,
            content_tag(:span, class: "p-2 text-secondary") do
              content_tag(:strong, "#{distance_target}KM", class: total_class)
            end
          ]
        end
      end,
      content_tag(:div, "", style: "clear: both;")
    ]
  end

  def render_total_pledged(pending, secured, default_currency) do
    color =
      if pending <= secured and pending != 0 do
        "text-success"
      else
        "text-secondary"
      end

    content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1 text-left #{color}") do
      [
        "Total Pledged ",
        content_tag(:i,
          class: "fa fa-question-circle-o text-secondary fa-1",
          data: [
            container: "body",
            toggle: "popover",
            placement: "top",
            title: "Total pledged",
            content:
              "means 'not yet secured' by either reaching a milestone or finishing a challenge.",
            trigger: "focus"
          ],
          tabindex: "0",
          id: "pledged_tooltip"
        ) do
        end,
        content_tag(:span, class: "float-right") do
          content_tag(
            :strong,
            "#{currency_to_symbol(default_currency) <> Integer.to_string(pending)}"
          )
        end
      ]
    end
  end

  def render_total_secured(secured, default_currency) do
    color =
      if secured <= 0 do
        "text-secondary"
      else
        "text-success"
      end

    content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1 text-left #{color}") do
      [
        "Total Secured ",
        content_tag(:i,
          class: "fa fa-question-circle-o text-secondary fa-1",
          data: [
            container: "body",
            toggle: "popover",
            placement: "top",
            title: "Total secured",
            content:
              "the transaction has been made after hitting a milestone or challenge is completed.",
            trigger: "focus"
          ],
          tabindex: "0",
          id: "secured_tooltip"
        ) do
        end,
        content_tag(:span, class: "float-right") do
          content_tag(
            :strong,
            "#{currency_to_symbol(default_currency) <> Integer.to_string(secured)}"
          )
        end
      ]
    end
  end

  def render_immediate_donation_secured_value_per_km(
        %Decimal{} = total_one_off_donations,
        distance_target
      ),
      do: Decimal.div(total_one_off_donations, Decimal.new(distance_target)) |> Decimal.round(1)

  def render_immediate_donation_secured_value_per_km(_, _), do: 0

  def render_pledge_per_km({nil, nil}), do: 0

  def render_pledge_per_km({%Decimal{} = total_km_pledges, _}),
    do: Decimal.to_string(total_km_pledges)

  def render_current_pledge_value(_, nil), do: 0

  def render_current_pledge_value(%Decimal{} = total_km_pledges, %Decimal{} = distance_covered) do
    Decimal.mult(total_km_pledges, distance_covered)
  end

  def render_km_current_distance_value({nil, nil}, _), do: 0

  def render_km_current_distance_value({%Decimal{} = total_km_pledges, _}, %NGOChal{} = challenge) do
    current_distance_value =
      Decimal.mult(total_km_pledges, challenge.distance_covered)
      |> Decimal.round(1)

    total_support =
      Decimal.mult(total_km_pledges, Decimal.new(challenge.distance_target))
      |> Decimal.round(1)

    cond do
      Decimal.cmp(current_distance_value, total_support) == :gt -> total_support
      Decimal.cmp(current_distance_value, total_support) == :lt -> current_distance_value
      true -> total_support
    end
  end

  def render_km_challenge_total_support(nil, _), do: 0

  def render_km_challenge_total_support(
        %Decimal{} = total_km_pledges,
        distance_target
      ) do
    distance_target = Decimal.new(distance_target)

    Decimal.mult(total_km_pledges, distance_target)
    |> Decimal.round(1)
    |> Decimal.to_string()
  end

  def render_current_pledges({nil, nil}, _), do: 0

  def render_current_pledges(
        {%Decimal{} = total_pledges, %Decimal{} = follow_on_donations_total},
        distance
      ),
      do:
        Decimal.mult(total_pledges, distance)
        |> Decimal.add(follow_on_donations_total)
        |> Decimal.to_string()

  def total_pledges({nil, nil}, _), do: 0

  def total_pledges(
        {%Decimal{} = total_pledges, %Decimal{} = follow_on_donations_total},
        distance
      ),
      do:
        Decimal.mult(total_pledges, distance)
        |> Decimal.add(follow_on_donations_total)
        |> Decimal.round()
        |> Decimal.to_integer()

  def hide_donor_pays_fees?(%NGO{} = ngo), do: ngo.hide_donor_pays_fees

  def render_status("expired"), do: "Finished"

  def render_status(status), do: String.capitalize(status)

  def user_firstname_or_team_name(%NGOChal{has_team: false, user: %{firstname: firstname}}),
    do: firstname

  def user_firstname_or_team_name(%NGOChal{has_team: true, team: %{name: name}}), do: name

  def challenge_with_team_has_members(%NGOChal{
        has_team: has_team,
        team: %{invitations_accepted: invitations_accepted}
      }),
      do: has_team and invitations_accepted > 0

  def challenge_with_team_has_members(_), do: false

  defp number_of_sent_and_accepted_invites(%NGOChal{
         has_team: true,
         team: %{invitations: invitations}
       }) do
    Enum.count(invitations, fn invitation ->
      invitation.status == "pending_acceptance" or invitation.status == "accepted"
    end)
  end

  def invitations_exhaused?(%NGOChal{has_team: true, team: %{count: count}} = challenge),
    do: count == number_of_sent_and_accepted_invites(challenge)

  def left_invitations(%NGOChal{has_team: true, team: %{count: count}} = challenge) do
    sent_and_accepted = number_of_sent_and_accepted_invites(challenge)

    cond do
      sent_and_accepted == count -> []
      sent_and_accepted < count -> Range.new(1, count - sent_and_accepted)
    end
  end

  def accepted_invitations(%NGOChal{has_team: true, team: %{invitations: invitations}}),
    do: Enum.count(invitations, fn invitation -> invitation.status == "accepted" end)

  def team_full?(%NGOChal{has_team: true, team: %{count: count}} = challenge),
    do: count == accepted_invitations(challenge)

  def pending_invitations(%NGOChal{has_team: true, team: %{invitations: invitations}}) do
    Enum.map(invitations, fn invitation ->
      if invitation.status == "pending_acceptance" do
        invitation
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def can_resend?(%TeamInvitations{updated_at: updated_at}),
    do: Timex.before?(Timex.now(), Timex.shift(updated_at, days: 1))

  def has_accepted_members?(%NGOChal{has_team: true, team: %{users: users}} = _challenge)
      when length(users) > 0,
      do: true

  def has_accepted_members?(%NGOChal{has_team: true, team: %{users: users}} = _challenge)
      when length(users) == 0,
      do: false
end
