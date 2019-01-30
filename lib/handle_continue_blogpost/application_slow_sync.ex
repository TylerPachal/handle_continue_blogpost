# This is the most naive application.  All of the children are started
# one-after-another, which leads to slow (but safe) startup and restarting
# of the supervision tree.

defmodule HandleContinueBlogpost.ApplicationSlowSync do
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
        data: get_data(type)
      }
      Logger.info("#{type} - init end")
      {:ok, state}
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
