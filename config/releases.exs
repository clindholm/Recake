import Config

host_url =
  System.get_env("HOST_URL") ||
    raise """
    environment variable HOST_URL is missing.
    """

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :bygg_app, ByggApp.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :bygg_app, ByggAppWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]],
    url: [host: host_url, port: 443, scheme: "https"]
  ],
  secret_key_base: secret_key_base,
  server: true

config :logger, level: :info
