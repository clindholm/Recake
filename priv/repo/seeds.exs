# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

time =
  NaiveDateTime.utc_now()
  |> NaiveDateTime.truncate(:second)

password =
  Pbkdf2.hash_pwd_salt("password")

users =
  ?a..?z
  |> Enum.map(fn c ->
    c = to_string([c])

    %{
      email: "#{c}@admin.com",
      hashed_password: password,
      company: "Admin #{String.upcase(c)} Company",
      phone: "1234",
      inserted_at: time,
      updated_at: time
    }
  end)

Recake.Repo.insert_all(Recake.Accounts.User, users)
