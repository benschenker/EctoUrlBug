defmodule EctoUrlBug.Repo do
  use Ecto.Repo,
    otp_app: :ecto_url_bug,
    adapter: Ecto.Adapters.Postgres
end
