defmodule Recake.Accounts.Invitation do
  use Ecto.Schema

  @rand_size 32

  schema "user_invitations" do
    field :token, :binary
    belongs_to :creator, Recake.Accounts.User

    timestamps()
  end

  def invitation(creator_id \\ nil) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {Base.url_encode64(token, padding: false), %Recake.Accounts.Invitation{token: token, creator_id: creator_id}}
  end
end
