defmodule RecakeWeb.ConnCase do
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
  by setting `use RecakeWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import RecakeWeb.Gettext
      import RecakeWeb.ConnCase

      alias RecakeWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint RecakeWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Recake.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Recake.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def html_document(%Plug.Conn{} = conn) do
    conn
    |> Phoenix.ConnTest.html_response(200)
    |> Floki.parse_document!()
  end

  def html_document(string) when is_binary(string) do
    string
    |> Floki.parse_document!()
  end

  def assert_selector(document, selector) do
    assert not Enum.empty?(Floki.find(document, selector)), "\"#{selector}\" not found"

    document
  end

  def assert_selector_attr(document, selector, attr, value) do
    attrs =
      document
      |> Floki.find(selector)
      |> Enum.flat_map(fn {_, attrs, _} ->
        attrs
        |> Enum.filter(fn {attr_, _} -> attr == attr_ end)
      end)

    assert Enum.all?(attrs, fn {_, value_} -> value == value_ end)

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

    assert Enum.any?(els, fn {_, _, children} -> Floki.raw_html(children) =~ content end),
           "\"#{content}\" in \"#{selector}\" not found"

    document
  end

  def refute_selector(document, selector) do
    assert Enum.empty?(Floki.find(document, selector)), "\"#{selector}\" was found"

    document
  end

  def refute_selector_content(document, selector, content) do
    els =
      document
      |> Floki.find(selector)

    refute Enum.any?(els, fn {_, _, children} -> Floki.raw_html(children) =~ content end),
           "\"#{content}\" in \"#{selector}\" found"

    document
  end

  def assert_content(document, content) do
    html = Floki.raw_html(document)

    assert html =~ content, "\"#{content}\" not present in \"#{html}\""

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
    |> assert_selector_content(".alert-#{to_string(type)} > p", "Flash")
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
    user = Recake.AccountsFixtures.user_fixture()
    %{conn: login_user(conn, user), user: user}
  end

  def login_user(conn, user) do
    token = Recake.Accounts.generate_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
