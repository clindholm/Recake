defmodule Recake.Repo.Migrations.AddId06RequirementToJobs do
  use Ecto.Migration

  def change do
    alter table("jobs") do
      add :id06_required, :bool, null: false, default: false
    end
  end
end
