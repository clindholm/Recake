defmodule ByggAppWeb.FormHelpers do
  @moduledoc """
  Conveniences for building form elements.
  """
  import Phoenix.HTML, only: [sigil_E: 2]
  import ByggAppWeb.HtmlHelpers

  def text_input(form, field, opts \\ []) do
    input(&Phoenix.HTML.Form.text_input/3, form, field, opts)
  end

  def password_input(form, field, opts \\ []) do
    input(&Phoenix.HTML.Form.password_input/3, form, field, opts)
  end

  defp input(type_f, form, field, opts) do
    label = Keyword.get(opts, :label) || Phoenix.HTML.Form.humanize(field)
    errors = error_tag(form, field)
    input_classes = class_list([
        {"form-input mt-1 block w-full", true},
        {"border-red-500 border-2", errors}
      ])

    ~E"""
    <div class="mb-4">
      <label class="block">
        <span class="text-gray-700"><%= label %></span>
        <%= type_f.(form, field, class: input_classes) %>
      </label>
      <%= errors %>
    </div>
    """
  end

  def checkbox(form, field) do
    label = Phoenix.HTML.Form.humanize(field)

    ~E"""
    <div class="mb-4">
      <label class="flex items-center mb-4">
        <%= Phoenix.HTML.Form.checkbox form, :remember_me, class: "form-checkbox" %>
        <span class="text-gray-700 ml-2"><%= label %></span>
      </label>
    </div>
    """
  end

  def submit(label, opts \\ []) do
    class = "btn btn-primary block"
    extra_classes = Keyword.get(opts, :class)
    class = if extra_classes, do: "#{class} #{extra_classes}", else: class

    ~E"""
    <%= Phoenix.HTML.Form.submit label, class: class %>
    """
  end

  defp error_tag(form, field) do
    errors = Enum.map(Keyword.get_values(form.errors, field), fn error ->
      Phoenix.HTML.Tag.content_tag(:li, ByggAppWeb.ErrorHelpers.translate_error(error))
    end)

    if Enum.empty?(errors) do
      nil
    else
      Phoenix.HTML.Tag.content_tag :ul, class: "text-red-500 mt-1 list-disc" do
        errors
      end
    end
  end
end
