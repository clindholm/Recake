defmodule ByggAppWeb.HtmlHelpers do
  import Phoenix.HTML, only: [sigil_E: 2]

  def class_list(classes) do
    Enum.reduce(classes, "", fn {class, include?}, acc ->
      if include? do
        case acc do
          "" ->
            class

          _ ->
            acc <> " " <> class

        end
      else
        acc
      end
    end)
  end

  def render_alert(conn, type) when type in [:info, :success, :error] do
    alert_type = Atom.to_string(type)
    ~E"""
    <%= if Phoenix.Controller.get_flash(conn, type) do %>
      <div class="alert alert-<%= alert_type %>  -mr-4 -ml-4 mb-4">
        <p><%= Phoenix.Controller.get_flash(conn, type) %></p>
      </div>
    <% end %>
    """
  end
end
