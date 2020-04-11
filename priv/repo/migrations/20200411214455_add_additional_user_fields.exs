defmodule ByggApp.Repo.Migrations.AddAdditionalUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :company, :string, null: false
      add :phone, :string, null: false
    end
  end
end
