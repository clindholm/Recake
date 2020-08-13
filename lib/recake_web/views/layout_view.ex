defmodule RecakeWeb.LayoutView do
  use RecakeWeb, :view

  import Phoenix.HTML

  @nav_link_classes "px-6 py-2 bg-white text-blue-800 hover:bg-gray-200 hover:no-underline"

  def nav_link(label, opts) do
    classes = Keyword.get(opts, :class)

    classes =
      if classes do
        "#{classes} #{@nav_link_classes}"
      else
        @nav_link_classes
      end

    opts = Keyword.put(opts, :class, classes)

    ~E"""
      <%= link label, opts %>
    """
  end

  def render_with_permission(user, permission, do: block) do
    if Enum.member?(user.admin_permissions, permission) do
      block
    else
      {:safe, ""}
    end
  end
end
