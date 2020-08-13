defmodule RecakeWeb.FormHelpers do
  @moduledoc """
  Conveniences for building form elements.
  """
  import Phoenix.HTML, only: [sigil_E: 2]
  import RecakeWeb.HtmlHelpers
  import RecakeWeb.Gettext

  def text_input(form, field, opts \\ []) do
    input(&Phoenix.HTML.Form.text_input/3, form, field, opts)
  end

  def password_input(form, field, opts \\ []) do
    input(&Phoenix.HTML.Form.password_input/3, form, field, opts)
  end

  defp input(type_f, form, field, opts) do
    label = Keyword.get(opts, :label) || Phoenix.HTML.Form.humanize(field)
    errors = error_tag(form, field)

    input_classes =
      class_list([
        {"form-input mt-1 block w-full", true},
        {"border-red-500 border-2", errors}
      ])

    opts =
      opts
      |> Keyword.take([:name, :id])
      |> Keyword.put(:class, input_classes)

    ~E"""
    <div class="mb-4">
      <label class="block">
        <span class="text-gray-700"><%= label %></span>
        <%= type_f.(form, field, opts) %>
      </label>
      <%= errors %>
    </div>
    """
  end

  def textarea(form, field, opts \\ []) do
    textarea(form, field, false, opts)
  end

  def textarea_with_counter(form, field, opts \\ []) do
    textarea(form, field, true, opts)
  end

  defp textarea(form, field, include_counter, opts) do
    label = Keyword.get(opts, :label) || Phoenix.HTML.Form.humanize(field)

    max_count =
      Phoenix.HTML.Form.input_validations(form, field)
      |> Keyword.get(:maxlength, 0)

    errors = error_tag(form, field)

    input_classes =
      class_list([
        {"form-textarea mt-1 block w-full", true},
        {"border-red-500 border-2", errors}
      ])

    textarea_opts = [
      class: input_classes,
      rows: Keyword.get(opts, :rows)
      ]

    textarea_opts =
      if include_counter do
        textarea_opts
        |> Keyword.put(:data_target, "character-counter.input")
        |> Keyword.put(:data_action, "input->character-counter#count")
      else
        textarea_opts
      end

    ~E"""
    <div class="mb-4"<%= if include_counter, do: " data-controller=character-counter data-character-counter-max-count=#{max_count}" %>>
      <label class="block">
        <span class="text-gray-700"><%= label %></span>
        <%= Phoenix.HTML.Form.textarea form,
              field,
              textarea_opts %>
        <%= if include_counter do %>
        <p class="text-sm text-right mt-1" data-target="character-counter.counter"><%= gettext("Max %{count} characters", count: max_count) %></p>
        <% end %>
      </label>
      <%= errors %>
    </div>
    """
  end

  def checkbox(form, field, opts \\ []) do
    label = Keyword.get(opts, :label) || Phoenix.HTML.Form.humanize(field)

    ~E"""
    <div class="mb-4">
      <label class="flex items-center">
        <%= Phoenix.HTML.Form.checkbox form, field, class: "form-checkbox" %>
        <span class="text-gray-700 ml-2"><%= label %></span>
      </label>
    </div>
    """
  end

  def toggle(form, field, opts \\ []) do
    label = Keyword.get(opts, :label) || Phoenix.HTML.Form.humanize(field)

    ~E"""
    <div class="my-6">
      <label class="toggle">
        <span class="text-gray-700 mr-2"><%= label %></span>
        <%= Phoenix.HTML.Form.checkbox form, field, class: "form-checkbox" %>
        <div>
          <span></span>
        </div>
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

  def layout_right(do: block) do
    ~E"""
    <div class="flex justify-end">
      <%= block %>
    </div>
    """
  end

  defp error_tag(form, field) do
    errors =
      Enum.map(Keyword.get_values(form.errors, field), fn error ->
        Phoenix.HTML.Tag.content_tag(:li, RecakeWeb.ErrorHelpers.translate_error(error), class: "validation-error")
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
