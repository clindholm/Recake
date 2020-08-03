defmodule Recake.AccountsFixtures do
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password(),
        company: "Company Inc.",
        organization_number: "12345654",
        contact_name: "Contact Person",
        phone: "(233) 555-123 456"
      })
      |> (& Recake.Accounts.change_user_registration(%Recake.Accounts.User{}, &1)).()
      |> Recake.Repo.insert()
    user
  end

  def invitation_fixture() do
    Recake.Accounts.create_invitation()
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
