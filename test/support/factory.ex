defmodule OmegaBravera.Factory do
  use ExMachina.Ecto, repo: OmegaBravera.Repo

  def user_factory do
    %OmegaBravera.Accounts.User{
      firstname: "John",
      lastname: "Doe",
      email: sequence(:email, &("john.doe.#{&1}@example.com"))
    }
  end

  def ngo_factory do
    %OmegaBravera.Fundraisers.NGO{
      name: "Save the children worldwide",
      stripe_id: "cus_lO1DEQWBbQAACfHO",
      slug: "scww"
    }
  end

  def ngo_challenge_factory do
    %OmegaBravera.Challenges.NGOChal{
      activity: sequence(:activity, ["walking", "biking", "running", "hiking"]),
      distance_target: sequence(:distance_target, [50, 75, 150, 250]),
      start_date: Timex.now,
      end_date: Timex.shift(Timex.now, days: 5),
      duration: 5,
      status: "status",
      user: build(:user),
      ngo: build(:ngo)
    }
  end
end
