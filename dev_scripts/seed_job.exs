user =
  (System.argv()
  |> List.first()) || "b"

user = Recake.Accounts.get_user_by_email("#{user}@admin.com")

Recake.Jobs.publish_job(user, %{ description: "Description", location: "Location", internal_id: "Test" })
