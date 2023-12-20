import Config

# Print only warnings and errors during test
config :logger, level: :error

config :ecto_url_bug, EctoUrlBug.Repo,
  url: "ecto://ecto_url_bug:ecto_url_bug@localhost:35432/ecto_url_bug",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
