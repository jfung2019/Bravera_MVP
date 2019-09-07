defmodule OmegaBraveraWeb.Api.Mutation.LoginTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation ($email: String!, $password: String!, $locale: String!) {
    login(email: $email, password: $password, locale: $locale) {
      userSession{
        token
        user{
          firstname
          lastname
        }
        userProfile{
          totalPoints
          totalKilometers
          totalChallenges
          totalRewards
          offerChallengesMap{
            live{
              id
              slug
            }
            expired{
              id
              slug
            }
            completed{
              id
              slug
            }
          }
        }
      }
    }
  }
  """
  def credential_fixture() do
    user = insert(:user, %{email: @email})

    credential_attrs = %{
      password: @password,
      password_confirmation: @password
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
      |> Repo.insert()

    credential
    |> Repo.preload(:user)
  end

  test "creating a user session" do
    credential = credential_fixture()

    response =
      post(
        build_conn(),
        "/api",
        %{
          query: @query,
          variables: %{
            "email" => @email,
            "password" => @password,
            "locale" => "en"
          }
        }
      )

    assert %{
             "data" => %{
               "login" => %{
                 "userSession" => %{
                   "token" => token,
                   "user" => user_data,
                   "userProfile" => user_profile
                 }
               }
             }
           } = json_response(response, 200)

    assert %{"firstname" => credential.user.firstname, "lastname" => credential.user.lastname} ==
             user_data

    guardian_sub = "user:#{credential.user_id}"
    assert {:ok, %{"sub" => ^guardian_sub}} = OmegaBravera.Guardian.decode_and_verify(token)

    assert %{
             "offerChallengesMap" => %{"completed" => [], "expired" => [], "live" => []},
             "totalChallenges" => 0,
             "totalKilometers" => nil,
             "totalPoints" => nil,
             "totalRewards" => 0
           } = user_profile
  end

  test "trying to login to a non-existing account" do
    response =
      post(
        build_conn(),
        "/api",
        %{
          query: @query,
          variables: %{
            "email" => @email,
            "password" => @password,
            "locale" => "en"
          }
        }
      )

    assert %{
             "errors" => [
               %{
                 "message" => "Seems you don't have an account, please sign up."
               }
             ]
           } = json_response(response, 200)
  end

  test "locale is requred to login" do
    credential_fixture()

    response =
      post(
        build_conn(),
        "/api",
        %{
          query: @query,
          variables: %{
            "email" => @email,
            "password" => @password,
            "locale" => nil
          }
        }
      )

    assert %{
             "errors" => [
               %{
                 "message" => "Argument \"locale\" has invalid value $locale."
               },
               %{
                 "message" => "Variable \"locale\": Expected non-null, found null."
               }
             ]
           } = json_response(response, 200)
  end

  test "only en and zh are the correct locales" do
    credential_fixture()

    response =
      post(
        build_conn(),
        "/api",
        %{
          query: @query,
          variables: %{
            "email" => @email,
            "password" => @password,
            "locale" => "fo"
          }
        }
      )

    assert %{
             "errors" => [
               %{
                 "message" => "Locale is required to login. Supported locales are: en, zh."
               }
             ]
           } = json_response(response, 200)
  end
end
