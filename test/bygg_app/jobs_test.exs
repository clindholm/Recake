defmodule ByggApp.JobsTest do
  use ByggApp.DataCase, async: true

  alias ByggApp.Jobs
  alias ByggApp.Jobs.Job

  describe "change_job/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Jobs.change_job(%Job{})
      assert changeset.required == [:description, :location, :timespan, :status, :user_id]
    end
  end

end
