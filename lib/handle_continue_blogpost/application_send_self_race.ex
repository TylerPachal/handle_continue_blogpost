# Here we are just using a single MyServer process, along with a new Spammer
# process to illustrate a race condition that can occur.  The Spammer will
# continuously send messages to the MyServer, and those messages can arrive
# before the :more_init message that MyServer sends to itself.  This leads to
# a crash.
#
# We will see in application_handle_continue.ex how to properly implement this.

defmodule HandleContinueBlogpost.ApplicationSendSelfRace do
  use Application

  defmodule MyServer do
    use GenServer
    require Logger

    def start_link(name) do
      # Our server process is now a named singleton
      GenServer.start_link(__MODULE__, name, name: name)
    end

    def init(name) do
      Logger.info("#{name} - init start")
      state = %{
        name: name,
        data: nil
      }

      self() |> send(:more_init)

      Logger.info("#{name} - init end")
      {:ok, state}
    end

    def handle_info(:more_init, state) do
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

  # Our new process which continuously sends messages to the other process
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
      # Sending messages using the :server name
      :ok = GenServer.cast(:server, {:increment, "id1"})
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
      # The :server atom will be passed through as the process name
      {MyServer, :server}
    ]

    opts = [strategy: :one_for_one, name: ContinueTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
