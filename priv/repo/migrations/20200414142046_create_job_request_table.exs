defmodule Recake.Repo.Migrations.CreateJobRequestTable do
  use Ecto.Migration

  def change do
    create table(:job_requests) do
      add :job_id, references(:jobs, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      add :state, :string, null: false, default: "pending"

      timestamps()
    end

    create unique_index(:job_requests, [:job_id, :recipient_id])
  end
end
