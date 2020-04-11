defmodule ByggApp.Jobs do
  alias ByggApp.Jobs.Job

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end
end
