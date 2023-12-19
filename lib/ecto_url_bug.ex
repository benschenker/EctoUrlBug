defmodule EctoUrlBug do
  def setup_db_table() do
    query = """
    CREATE TABLE forms (
        name VARCHAR(255) PRIMARY KEY
    );
    """

    EctoUrlBug.Repo.query!(query)
  end

  def add_row(name) do
    query = """
    INSERT INTO forms (name) VALUES ('#{name}');
    """

    EctoUrlBug.Repo.query!(query)
  end

  def get_rows() do
    query = """
    SELECT name FROM forms;
    """

    results = EctoUrlBug.Repo.query!(query)
    results.rows
  end
end
