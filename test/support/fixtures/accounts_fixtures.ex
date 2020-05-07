defmodule ByggApp.AccountsFixtures do
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password(),
        company: "Company Inc.",
        phone: "(233) 555-123 456"
      })
      |> (& ByggApp.Accounts.change_user_registration(%ByggApp.Accounts.User{}, &1)).()
      |> ByggApp.Repo.insert()
    user
  end

  def invitation_fixture() do
    ByggApp.Accounts.create_invitation()
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
