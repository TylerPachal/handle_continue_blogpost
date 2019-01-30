# The application shows how to use handle_continue to properly initialize
# processes in your supervision tree.  The handle_continue/2 callback in
# MyServer is trigger from init/1 and is guaranteed to run before any other
# messages in the mailbox (from the spammer) are processed.

defmodule HandleContinueBlogpost.ApplicationHandleContinue do
  use Application

  defmodule MyServer do
    use GenServer
    require Logger

    def start_link(name) do
      GenServer.start_link(__MODULE__, name, name: name)
    end

    def init(name) do
      Logger.info("#{name} - init start")
      state = %{
        name: name,
        data: nil
      }

      Logger.info("#{name} - init end")

      # Modified return value that will trigger the handle_continue callback
      {:ok, state, {:continue, :more_init}}
    end

    # New callback
    def handle_continue(:more_init, state) do
      data = get_data(state.name)
      updated_state = Map.put(state, :data, data)
      {:noreply, updated_state}
    end

    def handle_cast({:increment, id}, state) do
      Logger.info("#{state.name} - increment #{id}")
      updated_data = Map.update(state.data, id, 1, fn v -> v + 1 end)
      updated_state = Map.put(state, :data, updated_data)
      {:noreply, updated_state}
    end

    defp get_data(name) do
      Logger.info("#{name} - get_data start")

      # Pretend we are doing a network call here that returns some data
      Enum.random(2000..4000) |> Process.sleep()
      data = %{}

      Logger.info("#{name} - get_data end")
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
      # Constantly send messages to the servers
      Enum.each([:first, :second, :third], fn name ->
        :ok = GenServer.cast(name, {:increment, "id1"})
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
      Supervisor.child_spec({MyServer, :first}, id: make_ref()),
      Supervisor.child_spec({MyServer, :second}, id: make_ref()),
      Supervisor.child_spec({MyServer, :third}, id: make_ref())
    ]

    opts = [strategy: :one_for_one, name: ContinueTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
