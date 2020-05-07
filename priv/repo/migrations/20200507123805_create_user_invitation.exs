defmodule ByggApp.Repo.Migrations.CreateUserInvitation do
  use Ecto.Migration

  def change do
    create table(:user_invitations) do
      add :token, :binary, null: false

      timestamps()
    end

    create index(:user_invitations, [:token])
  end
end
