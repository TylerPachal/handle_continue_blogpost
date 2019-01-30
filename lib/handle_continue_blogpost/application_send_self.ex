# This was our first attempt at improving the startup time.  We introduce
# a handle_info/2 callback that will perform the data fetching.  From init/1
# we simply send ourself a message to trigger this callback.  This leads to a
# faster supervision tree startup, because each init/1 callback is now
# delegating work and not blocking for very long.
#
# As we will see in application_send_self_race.ex this is not a safe way to do
# things and can lead to race conditions.

defmodule HandleContinueBlogpost.ApplicationSendSelf do
  use Application

  defmodule MyServer do
    use GenServer
    require Logger

    def start_link(name) do
      GenServer.start_link(__MODULE__, name)
    end

    def init(name) do
      Logger.info("#{name} - init start")
      state = %{
        name: name,
        data: nil
      }

      # Send a message to ourselves to load the data outside of the synchronous init block
      self() |> send(:more_init)

      Logger.info("#{name} - init end")
      {:ok, state}
    end

    # Perform the HTTP call here, instead of the init/1 callback
    def handle_info(:more_init, state) do
      data = get_data(state.name)
      updated_state = Map.put(state, :data, data)
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

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({MyServer, :first}, id: make_ref()),
      Supervisor.child_spec({MyServer, :second}, id: make_ref()),
      Supervisor.child_spec({MyServer, :third}, id: make_ref())
    ]

    opts = [strategy: :one_for_one, name: ContinueTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
