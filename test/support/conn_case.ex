defmodule ByggAppWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ByggAppWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ByggAppWeb.Gettext
      import ByggAppWeb.ConnCase

      alias ByggAppWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ByggAppWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ByggApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ByggApp.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def assert_section_header(response, label) do
    assert response =~ "<h1 class=\"section-title\">#{label}</h1>"
  end

  def register_and_login_user(%{conn: conn}) do
    user = ByggApp.AccountsFixtures.user_fixture()
    %{conn: login_user(conn, user), user: user}
  end

  def login_user(conn, user) do
    token = ByggApp.Accounts.generate_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
