defmodule Recake.Repo.Migrations.AddRecruitCountToJobAndRequests do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :recruit_count, :integer, null: false, default: 1
    end

    alter table(:job_requests) do
      add :recruit_count, :integer, null: false, default: 1
    end
  end
end
