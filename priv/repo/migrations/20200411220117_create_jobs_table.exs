defmodule Recake.Repo.Migrations.CreateJobsTable do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :identifier, :string, null: false
      add :description, :text, null: false
      add :location, :string, null: false
      add :timespan, :string, null: false
      add :is_closed, :boolean, null: false, default: false
      timestamps()
    end
  end
end
