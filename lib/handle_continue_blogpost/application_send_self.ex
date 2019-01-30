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

    def start_link(type) do
      GenServer.start_link(__MODULE__, type, name: type)
    end

    def init(type) do
      Logger.info("#{type} - init start")
      state = %{
        type: type,
        data: nil
      }

      # Send a message to ourself to load the data outside of the synchronous
      # init block
      self() |> send(:more_init)

      Logger.info("#{type} - init end")
      {:ok, state}
    end

    # Trigger the HTTP call here, instead of ini the init/1 callback
    def handle_info(:more_init, state) do
      data = get_data(state.type)
      updated_state = Map.put(state, :data, data)
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

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({MyServer, :users}, id: make_ref()),
      Supervisor.child_spec({MyServer, :messages}, id: make_ref()),
      Supervisor.child_spec({MyServer, :items}, id: make_ref())
    ]

    opts = [strategy: :one_for_one, name: ContinueTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
