defmodule ByggApp.Accounts.Invitation do
  use Ecto.Schema

  @rand_size 32

  schema "user_invitations" do
    field :token, :binary

    timestamps()
  end

  def invitation_token() do
    token = :crypto.strong_rand_bytes(@rand_size)
    {Base.url_encode64(token, padding: false), %ByggApp.Accounts.Invitation{token: token}}
  end
end
