defmodule Utils.Changeset do
  import Ecto.Changeset

  def downcase_field(changeset, field) do
    value = get_field(changeset, field)
    if value do
      put_change(changeset, field, String.downcase(value))
    else
      changeset
    end
  end
end
