# This is the most naive application.  All of the children are started
# one-after-another, which leads to slow (but safe) startup and restarting
# of the supervision tree.

defmodule HandleContinueBlogpost.ApplicationSlowSync do
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
        data: get_data(name)
      }
      Logger.info("#{name} - init end")
      {:ok, state}
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
