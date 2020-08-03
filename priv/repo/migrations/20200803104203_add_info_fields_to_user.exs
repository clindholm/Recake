defmodule Recake.Repo.Migrations.AddInfoFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :contact_name, :string, null: false, default: "N/A"
      add :organization_number, :string, null: false, default: "N/A"
    end
  end
end
