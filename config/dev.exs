import Config

# Print only warnings and errors during test
config :logger, level: :error

config :ecto_url_bug, EctoUrlBug.Repo,
  username: "ecto_url_bug",
  password: "ecto_url_bug",
  hostname: "localhost",
  database: "ecto_url_bug",
  port: 35432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
