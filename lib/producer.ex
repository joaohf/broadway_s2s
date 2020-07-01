defmodule BroadwayS2S.Producer do
  @moduledoc """
  A S2S producer for Broadway.
  """

  use GenStage

  require Logger

  alias Broadway.{Message, Producer}

  @behaviour Producer

  @default_receive_interval 5000

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {client, opts} = Keyword.pop(opts, :client, BroadwayS2S.NifiClient)
    {receive_interval, opts} = Keyword.pop(opts, :receive_interval, @default_receive_interval)

    # {gen_stage_opts, opts} = Keyword.split(opts, [:buffer_size, :buffer_keep])
    # {on_success, opts} = Keyword.pop(opts, :on_success, :ack)
    # {on_failure, opts} = Keyword.pop(opts, :on_failure, :reject_and_requeue)

    # assert_valid_ack_option!(:on_success, on_success)
    # assert_valid_ack_option!(:on_failure, on_failure)

    # options = []

    config = init_client!(client, opts)

    send(self(), {:connect, :no_init_client})

    {:producer,
      %{
       demand: 0,
       receive_timer: nil,
       receive_interval: receive_interval,
       client: {client, config},
       conn_ref: nil,
       opts: opts
     }}
  end

  @impl GenStage
  def handle_demand(incoming_demand, %{demand: demand} = state) do
    handle_receive_messages(%{state | demand: demand + incoming_demand})
  end

  @impl GenStage
  def handle_info(:receive_messages, %{receive_timer: nil} = state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info(:receive_messages, state) do
    handle_receive_messages(%{state | receive_timer: nil})
  end

  @impl true
  def handle_info({:connect, mode}, state) when mode in [:init_client, :no_init_client] do
    {:noreply, [], connect(state, mode)}
  end

  def handle_info(_, state) do
    {:noreply, [], state}
  end

  @impl Producer
  def prepare_for_draining(%{receive_timer: receive_timer} = state) do
    receive_timer && Process.cancel_timer(receive_timer)
    {:noreply, [], %{state | receive_timer: nil}}
  end

  @impl true
  def terminate(_reason, state) do
    IO.inspect(_reason, label: "reason")
    %{client: client, conn_ref: conn_ref} = state

    #:ok = client.close_connection(conn_ref)
    :ok
  end

  defp handle_receive_messages(%{receive_timer: nil, demand: demand} = state) when demand > 0 do
    messages = receive_flowfiles_from_s2s(state, demand)
    new_demand = demand - length(messages)

    receive_timer =
      case {messages, new_demand} do
        {[], _} -> schedule_receive_messages(state.receive_interval)
        {_, 0} -> nil
        _ -> schedule_receive_messages(0)
      end

    {:noreply, messages, %{state | demand: new_demand, receive_timer: receive_timer}}
  end

  defp handle_receive_messages(state) do
    {:noreply, [], state}
  end

  defp receive_flowfiles_from_s2s(state, _total_demand) do
    %{client: {client, _config}, conn_ref: conn_ref} = state
    client.receive_flowfiles(conn_ref, nil)
  end

  defp schedule_receive_messages(interval) do
    Process.send_after(self(), :receive_messages, interval)
  end

  defp connect(state, mode) when mode in [:init_client, :no_init_client] do
    %{client: {client, config}, opts: opts} = state

    config =
      if mode == :no_init_client do
        config
      else
        init_client!(client, opts)
      end

    case client.setup(config) do
      {:ok, conn_ref} ->
        %{
          state
          | conn_ref: conn_ref
        }

      {:error, _reason} ->
        # TODO
        raise ArgumentError, "todo"
    end
  end

  defp init_client!(client, opts) do
    case client.init(opts) do
      {:ok, config} ->
        config

      {:error, message} ->
        raise ArgumentError, "invalid options given to #{inspect(client)}.init/1, " <> message
    end
  end
end
