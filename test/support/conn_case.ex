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

  def html_document(conn) do
    conn
    |> Phoenix.ConnTest.html_response(200)
    |> Floki.parse_document!()
  end

  def assert_selector(document, selector) do
    assert not Enum.empty?(Floki.find(document, selector)), "\"#{selector}\" not found"

    document
  end

  def assert_selector_times(document, selector, n) do
    els = Enum.count(Floki.find(document, selector))
    assert Enum.count(Floki.find(document, selector)) == n, "Found \"#{selector}\" #{els} times"

    document
  end

  def assert_selector_content(document, selector, content) do
    els =
      document
      |> Floki.find(selector)

    assert Enum.any?(els, fn {_,_,children} -> Floki.raw_html(children) =~ content end), "\"#{content}\" in \"#{selector}\" not found"

    document
  end

  def refute_selector_content(document, selector, content) do
    els =
      document
      |> Floki.find(selector)

    refute Enum.any?(els, fn {_,_,[actual_content]} -> actual_content =~ content end), "\"#{content}\" in \"#{selector}\" found"

    document
  end

  def assert_content(document, content) do
    html = Floki.raw_html(document)

    assert html =~ content, "\"#{content}\" not present in \"#{html}\""

    document
  end

  def assert_section_header(document, label) do
    document
    |> assert_selector_content("h1.section-title", label)

    document
  end

  def assert_render_flash(conn, route_f, type) do
    conn =
      conn
      |> Phoenix.ConnTest.fetch_flash()
      |> Phoenix.ConnTest.put_flash(type, "Flash")

    conn
    |> route_f.()
    |> html_document()
    |> assert_selector_content(".alert-#{ to_string(type) } > p", "Flash")
  end

  def assert_form(document, action, inputs) do
    form = Floki.find(document, "form[action=\"#{action}\"]")

    assert form != [], "Form not found"

    for input <- inputs do
      assert Floki.find(form, input) != [], "Input \"#{input}\" not found in form"
    end

    document
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
