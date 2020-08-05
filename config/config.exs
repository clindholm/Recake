# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :recake,
  ecto_repos: [Recake.Repo]

# Configures the endpoint
config :recake, RecakeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "U+hNteAXXgrBffv7zk/C8WJVodkLeOEwn1VTc0iK2uaF0tchDb9My+DD6MF/Ng40",
  render_errors: [view: RecakeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Recake.PubSub,
  live_view: [signing_salt: "2EhAYCIL"]

config :recake, RecakeWeb.Gettext, default_locale: "sv", locales: ~w(sv en)
config :timex, default_locale: "sv"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
