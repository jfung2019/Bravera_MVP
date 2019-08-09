defmodule OmegaBraveraWeb.Schema.Types.Account do
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
end
