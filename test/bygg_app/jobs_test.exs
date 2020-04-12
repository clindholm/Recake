defmodule ByggApp.JobsTest do
  use ByggApp.DataCase, async: true

  alias ByggApp.Jobs
  alias ByggApp.Jobs.Job

  alias ByggApp.Accounts.User

  import ByggApp.AccountsFixtures
  import ByggApp.JobsFixtures

  describe "get_job/1" do
    test "returns nil for non-existant job" do
      refute Jobs.get_job(1)
    end

    test "returns the job if it exists" do
      user = user_fixture()
      job = job_fixture(user)

      assert job == Jobs.get_job(job.id)
    end
  end

  describe "change_job/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Jobs.change_job(%Job{})
      assert changeset.required == [:description, :location, :timespan, :status, :user_id]
    end
  end

  describe "publish_job/2" do
    setup do
      %{ user: user_fixture() }
    end

    test "validates required fields" do
      {:error, changeset} = Jobs.publish_job(%User{}, %{})

      assert %{
        user_id: ["can't be blank"],
        description: ["can't be blank"],
        location: ["can't be blank"],
        timespan: ["can't be blank"],
      } = errors_on(changeset)
    end

    test "validates maximum length on description" do
      description = String.duplicate("A", 301)
      {:error, changeset} = Jobs.publish_job(%User{}, %{description: description})

      assert %{
        description: ["should be at most 300 character(s)"],
      } = errors_on(changeset)
    end

    test "publishes job for user", %{user: user} do
      {:ok, job} = Jobs.publish_job(user, %{
        description: "Description",
        location: "Location",
        timespan: "Timespan",
        })

      assert job == Jobs.get_job(job.id)
      job = ByggApp.Repo.preload(job, :user)
      assert job.user == user
    end
  end

end
