defmodule ByggApp.Repo.Migrations.CreateJobsTable do
  use Ecto.Migration

  def change do
    JobStatusEnum.create_type()

    create table(:jobs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :description, :text, null: false
      add :location, :string, null: false
      add :timespan, :string, null: false
      add :status, JobStatusEnum.type(), null: false, default: "opened"
      timestamps()
    end
  end
end
