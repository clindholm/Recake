defmodule RecakeWeb.LayoutViewTest do
  use RecakeWeb.ConnCase, async: true

  import Phoenix.HTML
  import Recake.AccountsFixtures

  import RecakeWeb.LayoutView

  describe "nav_link/2" do
    test "Simple" do
      nav_link("Test", to: "/test")
      |> safe_to_string()
      |> html_document()
      |> assert_selector_content("a", "Test")
      |> assert_selector_attr("a", "href", "/test")
      |> assert_selector_attr("a", "class", "px-6 py-2 bg-white text-blue-800 hover:bg-gray-200 hover:no-underline")
    end

    test "Different method" do
      nav_link("Test", to: "/test", method: :delete)
      |> safe_to_string()
      |> html_document()
      |> assert_selector_content("a", "Test")
      |> assert_selector_attr("a", "href", "/test")
      |> assert_selector_attr("a", "class", "px-6 py-2 bg-white text-blue-800 hover:bg-gray-200 hover:no-underline")
      |> assert_selector_attr("a", "data-method", "delete")
    end

    test "Extra classes" do
      nav_link("Test", to: "/test", class: "test")
      |> safe_to_string()
      |> html_document()
      |> assert_selector_attr("a", "class", "test px-6 py-2 bg-white text-blue-800 hover:bg-gray-200 hover:no-underline")
    end
  end

  describe "render_with_permission/3" do
    setup %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> login_user(user)

      %{
        conn: conn,
        user: user
      }
    end

    test "Without permission", %{user: user} do
      render_with_permission user, "test_permission" do
        ~E"""
          <h1>Test</h1>
        """
      end
      |> safe_to_string()
      |> html_document()
      |> refute_selector_content("h1", "Test")
    end

    test "With permission", %{user: user} do
      user = %{ user | admin_permissions: ["test_permission"] }

      render_with_permission user, "test_permission" do
        ~E"""
          <h1>Test</h1>
        """
      end
      |> safe_to_string()
      |> html_document()
      |> assert_selector_content("h1", "Test")
    end
  end
end
