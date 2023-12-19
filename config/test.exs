import Config

# Print only warnings and errors during test
config :logger, level: :error

config :ecto_url_bug, EctoUrlBug.Repo,
  username: "ecto_url_bug",
  password: "ecto_url_bug",
  hostname: "localhost",
  database: "ecto_url_bug",
  port: 35432,
  # uncomment this line to make the test fail
  # url: "ecto://ecto_url_bug:ecto_url_bug@localhost:35432/ecto_url_bug",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
