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

  describe "list_user_jobs/1" do
    test "no jobs" do
      user = user_fixture()

      assert Enum.empty?(Jobs.list_user_jobs(user))
    end

    test "returns active jobs" do
      user = user_fixture()
      active_job = job_fixture(user)
      _closed_job = job_fixture(user, %{status: :closed})

      assert Jobs.list_user_jobs(user) == [active_job]
    end

    test "returns only jobs created by the user" do
      user = user_fixture()
      user2 = user_fixture()
      user1_job = job_fixture(user)
      _user2_job = job_fixture(user2)

      assert Jobs.list_user_jobs(user) == [user1_job]
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

    test "creates job requests for other users", %{user: job_creator} do
      recipient1 = user_fixture()
      recipient2 = user_fixture()

      {:ok, job} = Jobs.publish_job(job_creator, %{
        description: "Description",
        location: "Location",
        timespan: "Timespan",
        })

      job = ByggApp.Repo.preload(job, :requests)
      job_creator = ByggApp.Repo.preload(job_creator, :job_requests)
      recipient1 = ByggApp.Repo.preload(recipient1, :job_requests)
      recipient2 = ByggApp.Repo.preload(recipient2, :job_requests)

      [request1 | [] ] = recipient1.job_requests
      [request2 | [] ] = recipient2.job_requests

      recipient_requests = MapSet.new([request1, request2])
      job_requests = MapSet.new(job.requests)

      assert Map.equal?(recipient_requests, job_requests)

      assert Enum.empty?(job_creator.job_requests)
    end
  end

end
