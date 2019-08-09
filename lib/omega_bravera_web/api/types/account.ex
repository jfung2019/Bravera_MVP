defmodule OmegaBraveraWeb.Api.Types.Account do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :email, :string
    field :firstname, :string
    field :lastname, :string
  end

  object :user_session do
    field :token, :string
    field :user, :user
  end

  input_object :credential do
    field :password, non_null(:string)
    field :password_confirm, non_null(:string)
  end

  input_object :user_signup_input do
    field :firstname, non_null(:string)
    field :lastname, non_null(:string)
    field :accept_terms, non_null(:boolean)
    field :location_id, non_null(:integer)
    # should create an email scalar type to validate.
    field :email, non_null(:string)
    field :credential, :credential
  end
end
