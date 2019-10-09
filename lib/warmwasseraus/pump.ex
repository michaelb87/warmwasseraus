defmodule Warmwasseraus.Pump do
  @socket_timeout 5000
  
  def handle_call(cmd) do
    opts = [:binary, active: false, send_timeout: @socket_timeout]
    with {:ok, socket} <- :gen_tcp.connect('10.0.0.242', 2701, opts) do
      :ok = :gen_tcp.send(socket, cmd)
      {:ok, msg} = :gen_tcp.recv(socket, 0, @socket_timeout)
      :gen_tcp.close(socket)
      msg
    else
      {:error, _} -> "" 
    end
  end

  def parse(cmd) do
    String.split(cmd, "\n")
  end

  def is_active() do
    msg = handle_call("heater get 1\n")
    parse(msg) |> Enum.at(3, "err") == "a=1"
  end

  def set_pump(pump_state) do
    msg = handle_call("heater set 1 a=#{pump_state}\n")
    parse(msg) |> Enum.at(0, "ERR")
  end
end
