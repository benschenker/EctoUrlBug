defmodule EctoUrlBug.RepoTest do
  use EctoUrlBug.DataCase

  alias EctoUrlBug.RepoManager

  test "setup custom db for a workspace" do
    workspace_id = Ecto.UUID.generate()
    RepoManager.set_workspace(workspace_id, true)
    EctoUrlBug.setup_db_table()
    EctoUrlBug.add_row("Luke Skywalker")
    assert EctoUrlBug.get_rows() == [["Luke Skywalker"]]
    RepoManager.destroy_repo(workspace_id, true)
  end

  test "setup 2 workspaces to different repos/dbs" do
    workspace_id = Ecto.UUID.generate()
    other_workspace_id = Ecto.UUID.generate()

    RepoManager.set_workspace(workspace_id, true)
    EctoUrlBug.setup_db_table()
    EctoUrlBug.add_row("Luke Skywalker")
    assert EctoUrlBug.get_rows() == [["Luke Skywalker"]]

    RepoManager.set_workspace(other_workspace_id, true)
    EctoUrlBug.setup_db_table()
    EctoUrlBug.add_row("Anakin Skywalker")
    assert EctoUrlBug.get_rows() == [["Anakin Skywalker"]]

    RepoManager.set_workspace(workspace_id, true)
    assert EctoUrlBug.get_rows() == [["Luke Skywalker"]]

    RepoManager.destroy_repo(workspace_id, true)
    RepoManager.destroy_repo(other_workspace_id, true)
  end
end
