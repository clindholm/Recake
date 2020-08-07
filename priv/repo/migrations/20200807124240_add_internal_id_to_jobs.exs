defmodule Recake.Repo.Migrations.AddInternalIdToJobs do
  use Ecto.Migration

  def change do
    alter table("jobs") do
      add :internal_id, :string, null: false, default: "Untitled job"
    end
  end
end
