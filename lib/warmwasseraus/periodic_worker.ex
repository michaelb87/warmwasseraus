defmodule Warmwasseraus.PeriodicWorker do
  use GenServer
  @initial_state %{name: nil, disable_at: nil}
  @refresh_interval 10_000 # 10 seconds
  @disable_after_seconds 5*60

  def init(state) do
    schedule_temp_fetch()
    {:ok, state}
  end

  def start_link(args) do
    id = Map.get(args, :id)
    GenServer.start_link(__MODULE__, %{@initial_state | name: id})
  end

  def handle_info(:temp_fetch, state) do
    is_active = Warmwasseraus.Pump.is_active()
    disable_at = get_disabled_time(is_active, state.disable_at)
    if is_active && (disable_at == nil) do
        IO.puts('disabling')
        Warmwasseraus.Pump.set_pump(0)
    end
    schedule_temp_fetch()
    {:noreply, %{state | disable_at: disable_at}}
  end

  def schedule_temp_fetch() do
    Process.send_after(self(), :temp_fetch, @refresh_interval)
  end

  def get_time do
    {status, dt} = :calendar.local_time() |> NaiveDateTime.from_erl()

    case status do
      :ok -> dt
      _ -> 'error getting time'
    end
  end

  def get_disabled_time(is_active, disable_at) do
    now = DateTime.utc_now()

    cond do
      is_active && disable_at == nil -> DateTime.add(now, @disable_after_seconds, :second)
      is_active && disable_at != nil && DateTime.compare(now, disable_at) == :lt -> disable_at
      true -> nil
    end
  end
end
