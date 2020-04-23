defmodule ByggApp.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @apps [
    :bygg_app
  ]

  @repos [
    ByggApp.Repo
  ]

  def migrate() do
    startup()

    Enum.each(@apps, &run_migrations_for/1)

    IO.puts("Success!")
  end

  defp startup() do
    IO.puts("Loading app")

    Application.load(:bygg_app)

    IO.puts("Starting dependencies")
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    IO.puts("Starting repos...")
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(ByggApp.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end
