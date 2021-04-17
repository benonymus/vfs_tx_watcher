defmodule TxWatcher.PendingTxs do
  use GenServer

  # the state itself could just be the list
  defmodule TxWatcher.State do
    defstruct pending_txs: []
  end

  alias TxWatcher.State

  @slack_webhook_url Application.compile_env!(:tx_watcher, :slack_webhook_url)

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
    GenServer.call(__MODULE__, :get)
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
  def handle_cast({:add, tx_id}, %State{pending_txs: pending_txs} = state) do
    msg_to_slack(:registered, tx_id)

    {:noreply, put_timer_ref(state, tx_id, pending_txs)}
  end

  @impl GenServer
  def handle_cast({:remove, tx_id}, %State{pending_txs: pending_txs} = state) do
    msg_to_slack(:confirmed, tx_id)

    {_tx_id, timer_ref} = Enum.find(pending_txs, {nil, nil}, fn {x, _} -> x == tx_id end)

    unless is_nil(timer_ref), do: Process.cancel_timer(timer_ref)

    {:noreply, %State{state | pending_txs: Enum.reject(pending_txs, fn {x, _} -> x == tx_id end)}}
  end

  @impl GenServer
  def handle_info({:pending, tx_id}, %State{pending_txs: pending_txs} = state) do
    msg_to_slack(:pending, tx_id)

    updated_pending_txs = Enum.reject(pending_txs, fn {x, _} -> x == tx_id end)

    {:noreply, put_timer_ref(state, tx_id, updated_pending_txs)}
  end

  @spec put_timer_ref(State.t(), String.t(), list(String.t())) :: State.t()
  defp put_timer_ref(state, tx_id, pending_txs) do
    timer_ref = Process.send_after(self(), {:pending, tx_id}, 120_000)
    %State{state | pending_txs: [{tx_id, timer_ref} | pending_txs]}
  end

  @spec msg_to_slack(atom(), String.t()) :: {:ok, pid()}
  defp msg_to_slack(type, tx_id) when type in [:registered, :pending, :confirmed] do
    msg =
      case type do
        :registered ->
          "Registered: #{tx_id}"

        :pending ->
          "Pending: #{tx_id}"

        :confirmed ->
          "Confirmed: #{tx_id}"
      end

    Task.start(__MODULE__, :send_msg, [msg])
  end

  defp msg_to_slack(_, _), do: :ok

  def send_msg(msg) do
    :httpc.request(
      :post,
      {@slack_webhook_url, [], 'application/json',
       Jason.encode!(%{
         text: msg
       })},
      [],
      []
    )
    |> IO.inspect()
  end
end
