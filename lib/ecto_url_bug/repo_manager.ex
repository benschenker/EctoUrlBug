defmodule EctoUrlBug.RepoManager do
  @doc """
  from https://underjord.io/ecto-multi-tenancy-dynamic-repos-part-2.html

  """
  use GenServer

  alias EctoUrlBug.Repo

  # Public API (client)

  def start_link(settings) when is_list(settings) do
    settings =
      Enum.reduce(
        settings,
        %{},
        fn {key, value}, new ->
          Map.put(new, key, value)
        end
      )

    start_link(settings)
  end

  def start_link(settings) when is_map(settings) do
    GenServer.start_link(__MODULE__, settings, name: __MODULE__)
  end

  def get_database_name(workspace_id) do
    "database_#{workspace_id}"
  end

  def get_workspace_options(workspace_id) do
    workspace_database = get_database_name(workspace_id)
    config = Application.get_env(:ecto_url_bug, Repo)

    config =
      case Keyword.fetch(config, :url) do
        {:ok, url} ->
          updated_config = Ecto.Repo.Supervisor.parse_url(url)

          config
          |> Keyword.merge(updated_config)
          |> Keyword.delete(:url)

        _ ->
          config
      end

    config
    |> Keyword.put(:name, nil)
    |> Keyword.put(:database, workspace_database)
  end

  def set_workspace(workspace_id, ensure_exists \\ false) do
    # Yes, this is entirely side-effects
    if ensure_exists do
      GenServer.cast(__MODULE__, {:ensure_repo_exists, workspace_id})
    end

    repo_pid = GenServer.call(__MODULE__, {:get_customer_pool, workspace_id})
    Repo.put_dynamic_repo(repo_pid)
    {:ok, repo_pid}
  end

  def unset_workspace(workspace_id) do
    GenServer.call(__MODULE__, {:get_customer_pool, workspace_id})
    Repo.put_dynamic_repo(Repo)
    :ok
  end

  def destroy_repo(workspace_id, wait \\ false) do
    # Added this bit, was not in original blog post
    # tests were passing but logging lots of errors without it, for ex:
    # (Postgrex.Error) FATAL 3D000 (invalid_catalog_name) database xx does not exist
    # (Postgrex.Error) FATAL 57P01 (admin_shutdown) terminating connection due to administrator command
    repo_pid = GenServer.call(__MODULE__, {:get_customer_pool, workspace_id})
    close_pool(repo_pid)

    unset_workspace(workspace_id)

    options =
      get_workspace_options(workspace_id)
      # Added this bit, was not in original blog post
      # tests would not actually drop the database without it
      |> Keyword.put(:force_drop, true)

    if wait do
      # Takes a bit
      Repo.__adapter__().storage_down(options)
    else
      Task.async(fn ->
        Repo.__adapter__().storage_down(options)
      end)
    end
  end

  # Callbacks (internal)

  @impl true
  def init(
        %{
          soft_limit: _soft_limit,
          hard_limit: _hard_limit
        } = settings
      ) do
    state = %{
      pools: %{},
      settings: settings
    }

    # Don't worry about warm up for now

    {:ok, state}
  end

  @impl true
  def handle_call(
        {:get_customer_pool, workspace_id},
        _from,
        state
      ) do
    {repo_pid, state} = get_connection_pool(workspace_id, state)
    {:reply, repo_pid, state}
  end

  @impl true
  def handle_cast(
        {:ensure_repo_exists, workspace_id},
        state
      ) do
    ensure_repo_exists(workspace_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        :clean_pool,
        %{
          pools: pools,
          settings: %{
            soft_limit: soft_limit
          }
        } = state
      ) do
    diff = map_size(pools) - soft_limit

    pools =
      if diff > 0 do
        close_oldest(pools, diff)
      else
        pools
      end

    state = %{state | pools: pools}

    {:noreply, state}
  end

  # Internal functions

  defp ensure_repo_exists(workspace_id) do
    options = get_workspace_options(workspace_id)
    res = Repo.__adapter__().storage_up(options)
    options = Keyword.put(options, :pool_size, 2)
    {:ok, repo_pid} = Repo.start_link(options)
    Repo.put_dynamic_repo(repo_pid)

    case res do
      # returns ok if it created the DB
      :ok ->
        # Do anything special after creating the DB for a first time
        nil

      _ ->
        nil
    end

    Repo.stop(1000)
    Repo.put_dynamic_repo(Repo)
  end

  defp start_connection_pool(
         workspace_id,
         %{pools: pools, settings: settings} = state
       ) do
    diff = map_size(pools) - settings.hard_limit

    pools =
      if diff > 0 do
        close_oldest(pools, diff)
      else
        pools
      end

    options =
      get_workspace_options(workspace_id)

    {:ok, repo_pid} = Repo.start_link(options)
    last_used = timestamp()
    pools = Map.put(pools, workspace_id, {repo_pid, last_used})

    GenServer.cast(:clean_pool, state)

    %{state | pools: pools}
  end

  defp get_connection_pool(workspace_id, %{pools: pools, settings: _settings} = state) do
    pool = Map.get(pools, workspace_id, nil)

    state =
      if pool == nil do
        start_connection_pool(workspace_id, state)
      else
        state
      end

    %{pools: pools} = state

    {repo_pid, _last_used} = Map.get(pools, workspace_id, nil)

    # Update usage timestamp
    pools = Map.put(pools, workspace_id, {repo_pid, timestamp()})
    state = Map.put(state, :pools, pools)

    GenServer.cast(:clean_pool, state)

    {repo_pid, state}
  end

  defp close_oldest(pools, number) do
    {trim, keep} =
      pools
      |> Enum.sort_by(fn {_customer_id, {_repo_pid, last_used}} ->
        last_used
      end)
      |> Enum.split(number)

    for {_customer_id, {repo_pid, _last_used}} <- trim do
      close_pool(repo_pid)
    end

    # Recreate map for the rest
    Enum.reduce(keep, %{}, fn {customer_id, pool}, pools ->
      Map.put(pools, customer_id, pool)
    end)
  end

  defp close_pool(repo_pid) do
    Repo.put_dynamic_repo(repo_pid)
    Repo.stop(1000)
  end

  defp timestamp do
    DateTime.utc_now()
  end
end
