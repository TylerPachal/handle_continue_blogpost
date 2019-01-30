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

    def start_link(type) do
      GenServer.start_link(__MODULE__, type, name: type)
    end

    def init(type) do
      Logger.info("#{type} - init start")
      state = %{
        type: type,
        data: nil
      }

      self() |> send(:more_init)

      Logger.info("#{type} - init end")
      {:ok, state}
    end

    def handle_info(:more_init, state) do
      data = get_data(state.type)
      updated_state = Map.put(state, :data, data)
      {:noreply, updated_state}
    end

    # Some sort of async operation that needs to be done on the data
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
