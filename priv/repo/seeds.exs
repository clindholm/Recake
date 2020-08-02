# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

user1 = Recake.Repo.insert!(
  Recake.Accounts.User.registration_changeset(%Recake.Accounts.User{}, %{
    email: "a@admin.com",
    password: "password",
    company: "Admin Company",
    phone: "1234"
  })
)

user2 = Recake.Repo.insert!(
  Recake.Accounts.User.registration_changeset(%Recake.Accounts.User{}, %{
    email: "b@admin.com",
    password: "password",
    company: "Admin B Company",
    phone: "1234"
  })
)

_job1 = Recake.Repo.insert!(
  Recake.Jobs.Job.changeset(%Recake.Jobs.Job{ user_id: user1.id}, %{
    description: "A job description",
    location: "Location",
  })
)

job2 = Recake.Repo.insert!(
  Recake.Jobs.Job.changeset(%Recake.Jobs.Job{ user_id: user2.id}, %{
    description: "A job description",
    location: "Location",
  })
)

job2 = Recake.Repo.insert!(
  %Recake.Jobs.Request{ job_id: job2.id, recipient_id: user1.id}
)
