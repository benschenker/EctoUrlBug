defmodule EctoUrlBug.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EctoUrlBug.Repo,
      {EctoUrlBug.RepoManager, %{soft_limit: 10, hard_limit: 20}}
    ]

    opts = [strategy: :one_for_one, name: EctoUrlBug.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
