defmodule BroadwayS2SExample.Worker do
  use Broadway

  import Api.Worker, only: [get_quote: 1]

  alias Broadway.Message

  @hostname "localhost"
  @port 8080
  @output_port "c62bad66-0172-1000-a957-7ec79ed4f525"
  @protocol :raw
  @lif "lo"

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: BroadwayS2SExample.Worker,
      producer: [
        module:
          {BroadwayS2S.Producer,
           [
             hostname: @hostname,
             port: @port,
             port_id: @output_port,
             local_network_interface: @lif,
             transport_protocol: @protocol
           ]},
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        default: [
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, message, _) do
    message
    |> Message.update_data(fn symbol ->
      price =
        symbol
        |> get_quote

      display_quote(symbol, price)
    end)
  end

  @impl true
  def handle_batch(_, messages, _, _) do
    list = messages |> Enum.map(fn e -> e.data end)
    IO.inspect(list, label: "Got batch of finished jobs from processors, sending ACKs to SQS as a batch.")
    messages
  end

  def transform(event, _opts) do
    %Message{
      data: String.replace(event.data, ~s("), ""),
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end

  def ack(:ack_id, _successful, _failed) do
    :ok
  end

  defp display_quote(symbol, price) do
    IO.puts("#{symbol} - #{price}")
  end
end
