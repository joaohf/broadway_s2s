defmodule BroadwayS2S.NifiClient do
  @moduledoc false

  require Logger

  alias Broadway.{Message, Acknowledger}

  @behaviour BroadwayS2S.S2SClient

  @impl true
  def init(opts) do
    with {:ok, hostname} <- validate(opts, :hostname, required: true),
         {:ok, port} <- validate(opts, :port, required: true),
         {:ok, transport_protocol} <- validate(opts, :transport_protocol, default: :raw),
         {:ok, local_network_interface} <-
           validate(opts, :local_network_interface, default: "lo"),
         {:ok, port_id} <- validate(opts, :port_id, required: true) do
      {:ok,
       %{
         hostname: hostname,
         port: port,
         transport_protocol: transport_protocol,
         local_network_interface: local_network_interface,
         port_id: port_id
       }}
    end
  end

  @impl true
  def setup(config) do
    {:ok, _pid} = :nifi_s2s.create_client(config)
  end

  @impl true
  @spec receive_flowfiles(any, any) :: none
  def receive_flowfiles(client, _config) do
    ack_ref = nil
    {:ok, flowfiles} = :nifi_s2s.receive_flowfiles(client)
    wrap_received_messages(flowfiles, ack_ref)
  end

  @impl true
  def close_connection(client) do
    :ok = :nifi_s2s.close(client)
  end

  defp wrap_received_messages(flowfiles, ack_ref) do
    wrap_received_messages(flowfiles, [], ack_ref)
  end

  defp wrap_received_messages({:empty, _}, acc, _) do
    acc
  end

  defp wrap_received_messages({{:value, flowfile}, flowfiles}, acc, ack_ref) do
    data = :nifi_flowfile.get_content(flowfile)
    metadata = :nifi_flowfile.get_attributes(flowfile)
    acknowledger = build_acknowledger(flowfile, ack_ref)

    message = %Message{data: data, metadata: metadata, acknowledger: acknowledger}

    flowfiles |> :nifi_flowfile.remove() |> wrap_received_messages([message | acc], ack_ref)
  end

  defp wrap_received_messages(flowfiles, acc, ack_ref) do
    wrap_received_messages(:nifi_flowfile.remove(flowfiles), acc, ack_ref)
  end

  defp build_acknowledger(_flowfile, ack_ref) do
    # TODO get flowfile id
    receipt = %{id: "message.message_id"}
    {__MODULE__, ack_ref, %{receipt: receipt}}
  end

  defp validate(opts, key, options \\ []) when is_list(opts) do
    has_key = Keyword.has_key?(opts, key)
    required = Keyword.get(options, :required, false)
    default = Keyword.get(options, :default)

    cond do
      has_key ->
        validate_option(key, opts[key])

      required ->
        {:error, "#{inspect(key)} is required"}

      default != nil ->
        validate_option(key, default)

      true ->
        {:ok, nil}
    end
  end

  defp validate_option(:hostname, value) when not is_binary(value) or value == "",
    do: validation_error(:hostname, "a non empty string", value)

  defp validate_option(:port_id, value) when not is_binary(value) or value == "",
    do: validation_error(:port_id, "a non empty string", value)

  defp validate_option(:port, value) when not is_integer(value) or value <= 0,
    do: validation_error(:port, "an integer value great than 0", value)

  defp validate_option(:local_network_interface, value) when not is_binary(value) or value == "",
    do: validation_error(:local_network_interface, "a non empty string", value)

  defp validate_option(_, value), do: {:ok, value}

  defp validation_error(option, expected, value) do
    {:error, "expected #{inspect(option)} to be #{expected}, got: #{inspect(value)}"}
  end
end
