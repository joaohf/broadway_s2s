defmodule BroadwayS2SExample do
  @moduledoc false

  @csv_file "./data/companylist.csv"

  @hostname "localhost"
  @port 8080
  @input_port "8f7630f3-0172-1000-8f82-0a81a44f3d30"

  def dispatch do
    s2s_config = %{
      :hostname => @hostname,
      :port => @port,
      :transport_protocol => :raw,
      :local_network_interface => "lo0",
      :port_id => @input_port |> to_charlist()
    }

    {:ok, pid} = :nifi_s2s.create_client(s2s_config)

    flowfiles = :nifi_flowfile.new()

    @csv_file
    |> File.stream!()
    |> Stream.drop(1)
    |> Stream.map(&String.trim(&1, "\n"))
    |> Stream.map(&String.split(&1, ","))
    |> Enum.map(fn columns -> List.first(columns) end)
    |> Enum.reduce(flowfiles, &make_flowfiles/2)
    |> transfer(pid)

    :ok = :nifi_s2s.close(pid)
  end

  defp make_flowfiles(symbol, flowfiles) do
    attr = %{"symbol" => symbol}
    :nifi_flowfile.add(attr, symbol, flowfiles)
  end

  defp transfer(flowfiles, pid) do
    :ok = :nifi_s2s.transfer_flowfiles(pid, flowfiles)
  end
end
