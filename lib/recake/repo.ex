defmodule Recake.Repo do
  use Ecto.Repo,
    otp_app: :recake,
    adapter: Ecto.Adapters.Postgres
end
