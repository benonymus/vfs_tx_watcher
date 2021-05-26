defmodule TxWatcher.PendingTxs do
  @moduledoc """
  Genserver for the pending transactions
  """
  use GenServer
  alias TxWatcher.ExternalRequests

  # the state itself could just be the list
  defmodule State do
    @moduledoc """
    State of TxWatcher.PendingTxs
    """
    @type t :: %__MODULE__{
            pending_txs: list()
          }
    defstruct pending_txs: []
  end

  alias State

  @pending_time Application.compile_env!(:tx_watcher, :pending_time)

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  @spec start_link(term()) :: {:ok, pid()}
  def start_link(_),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec get() :: {:ok, list(String.t())}
  def get() do
    IO.puts("here")
    GenServer.call(__MODULE__, :get)
  end

  @spec __clear__() :: :ok
  def __clear__() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec add_registered(String.t()) :: :ok
  def add_registered(tx_id) do
    GenServer.cast(__MODULE__, {:add, tx_id})
  end

  @spec remove_registered(String.t()) :: :ok
  def remove_registered(tx_id) do
    GenServer.cast(__MODULE__, {:remove, tx_id})
  end

  @impl GenServer
  def init(_) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call(:get, _, %State{pending_txs: pending_txs} = state) do
    {:reply, {:ok, pending_txs}, state}
  end

  @impl GenServer
  def handle_call(:clear, _, _state) do
    {:reply, :ok, %State{pending_txs: []}}
  end

  @impl GenServer
  def handle_cast({:add, tx_id}, %State{pending_txs: pending_txs} = state) do
    build_message(:registered, tx_id)

    {:noreply, put_timer_ref(state, tx_id, pending_txs)}
  end

  @impl GenServer
  def handle_cast({:remove, tx_id}, %State{pending_txs: pending_txs} = state) do
    build_message(:confirmed, tx_id)

    {_tx_id, timer_ref} = Enum.find(pending_txs, {nil, nil}, fn {x, _} -> x == tx_id end)

    unless is_nil(timer_ref), do: Process.cancel_timer(timer_ref)

    {:noreply, %State{state | pending_txs: Enum.reject(pending_txs, fn {x, _} -> x == tx_id end)}}
  end

  @impl GenServer
  def handle_info({:pending, tx_id}, %State{pending_txs: pending_txs} = state) do
    build_message(:pending, tx_id)

    updated_pending_txs = Enum.reject(pending_txs, fn {x, _} -> x == tx_id end)

    {:noreply, put_timer_ref(state, tx_id, updated_pending_txs)}
  end

  @spec put_timer_ref(term(), String.t(), list(String.t())) :: term()
  defp put_timer_ref(state, tx_id, pending_txs) do
    timer_ref = Process.send_after(self(), {:pending, tx_id}, @pending_time)
    %State{state | pending_txs: [{tx_id, timer_ref} | pending_txs]}
  end

  @spec build_message(atom(), String.t()) :: {:ok, pid()}
  defp build_message(type, tx_id) when type in [:registered, :pending, :confirmed] do
    msg =
      case type do
        :registered ->
          "Registered: #{tx_id}"

        :pending ->
          "Pending: #{tx_id}"

        :confirmed ->
          "Confirmed: #{tx_id}"
      end

    ExternalRequests.send_msg_to_slack(msg)
  end

  defp build_message(_, _), do: :ok
end
