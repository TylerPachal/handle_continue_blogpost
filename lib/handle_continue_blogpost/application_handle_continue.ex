# The application shows how to use handle_continue to properly initialize
# processes in your supervision tree.  The handle_continue/2 callback in
# MyServer is trigger from init/1 and is guaranteed to run before any other
# messages in the mailbox (from the spammer) are processed.

defmodule HandleContinueBlogpost.ApplicationHandleContinue do
  use Application

  defmodule MyServer do
    use GenServer
    require Logger

    def start_link(type) do
      GenServer.start_link(__MODULE__, type, name: type)
    end

    def init(type) do
      Logger.info("#{type} - init start")
      state = %{
        type: type,
        data: nil
      }

      Logger.info("#{type} - init end")

      # Modified return value that will trigger the handle_continue callback
      {:ok, state, {:continue, :more_init}}
    end

    # New callback
    def handle_continue(:more_init, state) do
      data = get_data(state.type)
      updated_state = Map.put(state, :data, data)
      {:noreply, updated_state}
    end

    def handle_cast({:increment, id}, state) do
      Logger.info("#{state.type} - increment #{id}")
      updated_data = Map.update(state.data, id, 1, fn v -> v + 1 end)
      updated_state = Map.put(state, :data, updated_data)
      {:noreply, updated_state}
    end

    defp get_data(:users), do: http_get("http://api.website.com/user_config")
    defp get_data(:messages), do: http_get("http://api.website.com/recent_messages")
    defp get_data(:items), do: http_get("http://api.website.com/item_catalog")

    defp http_get(url) do
      Logger.info("start #{url}")

      # Pretend we are doing a network call here that returns some data
      Enum.random(2000..4000) |> Process.sleep()
      data = %{}

      Logger.info("end #{url}")
      data
    end
  end

  defmodule Spammer do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
      loop()
      {:ok, :state}
    end

    def handle_info(:send_message, state) do
      Enum.each([:users, :messages, :items], fn name ->
        :ok = GenServer.cast(name, {:increment, "id"})
      end)
      loop()
      {:noreply, state}
    end

    defp loop() do
      self() |> send(:send_message)
    end
  end

    def start(_type, _args) do
      children = [
        Spammer,
        Supervisor.child_spec({MyServer, :users}, id: make_ref()),
        Supervisor.child_spec({MyServer, :messages}, id: make_ref()),
        Supervisor.child_spec({MyServer, :items}, id: make_ref())
      ]

      opts = [strategy: :one_for_one, name: ContinueTest.Supervisor]
      Supervisor.start_link(children, opts)
    end
end
