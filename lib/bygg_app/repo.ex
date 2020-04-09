defmodule ByggApp.Repo do
  use Ecto.Repo,
    otp_app: :bygg_app,
    adapter: Ecto.Adapters.Postgres
end
