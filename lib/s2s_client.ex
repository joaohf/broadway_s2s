defmodule BroadwayS2S.S2SClient do
  @moduledoc false

  @typep config :: %{
           hostname: String.t(),
           port: non_neg_integer(),
           port_id: String.t(),
           local_network_interface: String.t(),
           transport_protocol: :raw
         }

  @callback init(opts :: any) :: {:ok, config} | {:error, any}
  @callback setup(config) :: {:ok, pid()} | {:error, any}
  @callback receive_flowfiles(client :: pid(), config) :: :nifi_flowfile.flowfile()
  @callback close_connection(client :: pid()) :: :ok | {:error, any}
end
