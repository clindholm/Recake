defmodule Recake.Repo.Migrations.AddAdminPermissionsToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :admin_permissions, {:array, :string}, null: false, default: []
    end
  end
end
