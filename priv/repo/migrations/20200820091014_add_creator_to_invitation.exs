defmodule Recake.Repo.Migrations.AddCreatorToInvitation do
  use Ecto.Migration

  def change do
    alter table(:user_invitations) do
      add :creator_id, references(:users, on_delete: :nilify_all)
    end
  end
end
