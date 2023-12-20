# EctoUrlBug

A repo that shows how the url config option of ecto clobbers the database name for dynamic repos as described in https://github.com/elixir-ecto/ecto/issues/4331

## Setup

- asdf install
- mix test
  - should pass
- uncomment line 13 in config/test.exs
- mix test
  - fails
