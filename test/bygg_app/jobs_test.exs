defmodule Recake.JobsTest do
  use Recake.DataCase, async: true

  alias Recake.Jobs
  alias Recake.Jobs.{Job, Request}

  alias Recake.Accounts.User

  import Recake.AccountsFixtures
  import Recake.JobsFixtures
  import RecakeWeb.Gettext

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

  describe "get_job_request/1" do
    test "returns nil for non-existant job request" do
      refute Jobs.get_job_request(1)
    end

    test "returns the job request if it exists" do
      user = user_fixture()
      job = job_fixture(user)
      request = job_request_fixture(user, job)

      assert request.id == Jobs.get_job_request(request.id).id
    end

    test "preloads job and job creator" do
      user = user_fixture()
      job = job_fixture(user)
      request = job_request_fixture(user, job)
      request = Jobs.get_job_request(request.id)

      assert request.job.description == job.description
      assert request.job.user.company == user.company
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
      _closed_job = job_fixture(user, %{state: "closed"})

      job_ids =
        Jobs.list_user_jobs(user)
        |> Enum.map(& &1.id)

      assert job_ids == [active_job.id]
    end

    test "returns only jobs created by the user" do
      user = user_fixture()
      user2 = user_fixture()
      user1_job = job_fixture(user)
      _user2_job = job_fixture(user2)

      job_ids =
        Jobs.list_user_jobs(user)
        |> Enum.map(& &1.id)

      assert job_ids == [user1_job.id]
    end

    test "preloads requests and recipients" do
      user = user_fixture()
      recipient = user_fixture()
      job = job_fixture(user)
      _request = job_request_fixture(recipient, job)

      jobs = Jobs.list_user_jobs(user)

      preloaded_recipient =
        jobs
        |> List.first()
        |> (& &1.requests).()
        |> List.first()
        |> (& &1.recipient).()

      assert preloaded_recipient.id == recipient.id
    end
  end

  describe "list_user_incoming_requests/1" do
    test "no requests" do
      user = user_fixture()

      assert Enum.empty?(Jobs.list_user_incoming_requests(user))
    end

    test "returns pending requests" do
      user = user_fixture()
      job = job_fixture(user)
      job2 = job_fixture(user)
      request1 = job_request_fixture(user, job, "pending")
      _request2 = job_request_fixture(user, job2, "accepted")

      request_ids =
        Jobs.list_user_incoming_requests(user)
        |> Enum.map(& &1.id)

      assert request_ids == [request1.id]
    end

    test "returns only requests of the user" do
      user = user_fixture()
      user2 = user_fixture()
      job = job_fixture(user)
      request1 = job_request_fixture(user, job, "pending")
      _request2 = job_request_fixture(user2, job, "pending")

      request_ids =
        Jobs.list_user_incoming_requests(user)
        |> Enum.map(& &1.id)

      assert request_ids == [request1.id]
    end

    test "preloads job and job creator" do
      user = user_fixture()
      job = job_fixture(user)
      _request = job_request_fixture(user, job)

      request =
        Jobs.list_user_incoming_requests(user)
        |> List.first()

      assert request.job.description == job.description
      assert request.job.user.company == user.company
    end
  end

  describe "change_job/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Jobs.change_job(%Job{})

      assert changeset.required == [
               :description,
               :location,
               :user_id
             ]
    end
  end

  describe "publish_job/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates required fields" do
      {:error, changeset} = Jobs.publish_job(%User{}, %{})

      error = dgettext("errors", "can't be blank")

      assert %{
               user_id: [^error],
               description: [^error],
               location: [^error],
             } = errors_on(changeset)
    end

    test "validates maximum length" do
      too_long = String.duplicate("A", 301)

      {:error, changeset} =
        Jobs.publish_job(%User{}, %{description: too_long})

      description_error =
        dngettext(
          "errors",
          "should be at most %{count} character(s)",
          "should be at most %{count} character(s)",
          300
        )

      assert %{
               description: [^description_error]
             } = errors_on(changeset)
    end

    test "publishes job for user", %{user: user} do
      {:ok, job} =
        Jobs.publish_job(user, %{
          description: "Description",
          location: "Location",
        })

      assert job == Jobs.get_job(job.id)
      job = Recake.Repo.preload(job, :user)
      assert job.user == user
    end

    test "creates job requests for other users", %{user: job_creator} do
      recipient1 = user_fixture()
      recipient2 = user_fixture()

      {:ok, job} =
        Jobs.publish_job(job_creator, %{
          description: "Description",
          location: "Location",
        })

      job = Recake.Repo.preload(job, :requests)
      job_creator = Recake.Repo.preload(job_creator, :job_requests)
      recipient1 = Recake.Repo.preload(recipient1, :job_requests)
      recipient2 = Recake.Repo.preload(recipient2, :job_requests)

      [request1 | []] = recipient1.job_requests
      [request2 | []] = recipient2.job_requests

      recipient_requests = MapSet.new([request1, request2])
      job_requests = MapSet.new(job.requests)

      assert Map.equal?(recipient_requests, job_requests)

      assert Enum.empty?(job_creator.job_requests)
    end
  end

  describe "update_job/2" do
    setup do
      user = user_fixture()
      job = job_fixture(user)

      %{
        job: job
      }
    end

    test "updates the job", %{job: job} do
      {:ok, job} = Jobs.update_job(job, %{
        description: "Updated description",
      })

      updated_job = Repo.get!(Job, job.id)

      assert updated_job.description == "Updated description"
    end

    test "validates the job", %{job: job} do
      {:error, changeset} = Jobs.update_job(job, %{
        description: "",
      })

      error = dgettext("errors", "can't be blank")

      assert %{
        description: [^error]
      } = errors_on(changeset)
    end
  end

  describe "resolve_request/2" do
    setup do
      user = user_fixture()
      job = job_fixture(user)
      request = job_request_fixture(user, job)

      %{
        request: request
      }
    end

    test "accepts request", %{request: request} do
      {:ok, updated_request} = Jobs.resolve_request(request, :available)

      assert updated_request.state == "available"
      assert ^updated_request = Repo.get!(Request, request.id)
    end

    test "rejects request", %{request: request} do
      {:ok, updated_request} = Jobs.resolve_request(request, :unavailable)

      assert updated_request.state == "unavailable"
      assert ^updated_request = Repo.get!(Request, request.id)
    end

    test "invalid resolution", %{request: request} do
      assert Jobs.resolve_request(request, :invalid) == {:error, :invalid_resolution}
    end
  end
end
