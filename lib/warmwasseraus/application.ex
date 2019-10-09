defmodule Warmwasseraus.Application do
  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Warmwasseraus.PeriodicWorker, %{id: :periodic_worker}}, id: :periodic_worker)
    ]

    opts = [strategy: :one_for_one, name: Warmwasseraus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
