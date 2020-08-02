defmodule Recake.Repo.Migrations.AlterColumnsOnJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      remove :identifier, :string, null: false, default: "ID"
      remove :timespan, :string, null: false, default: "1"
      remove :is_closed, :boolean, null: false, default: false
      add :state, :string, null: false, default: "active"
    end
  end
end
