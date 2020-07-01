defmodule Api.Worker do
  use GenServer

  @name AW

  ## Client API
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options ++ [name: @name])
  end

  def get_quote(symbol) do
    GenServer.call(@name, {:symbol, symbol})
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:symbol, symbol}, _from, state) do
    case quote_of(symbol) do
      {:ok, price} ->
        {:reply, "$#{Float.to_string(price, decimals: 2)}", state}

      {:error, message} ->
        {:reply, message, state}

      _ ->
        {:reply, :error, state}
    end
  end

  ## Helper Functions

  defp quote_of(_symbol) do
    # could get the real quote value here
    value = 10.50
    {:ok, value}
  end
end
