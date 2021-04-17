defmodule TxWatcherWeb.PendingTxsTest do
  use TxWatcherWeb.ConnCase
  alias TxWatcher.PendingTxs

  setup do
    on_exit(fn -> :ok = PendingTxs.__clear__() end)
  end

  test "add_registered tx_id and check that it is added" do
    tx_id = "1"
    PendingTxs.add_registered(tx_id)

    {:ok, [{saved_tx_id, _}]} = PendingTxs.get()

    assert saved_tx_id == tx_id
  end

  test "check for new timer_ref after previous expires" do
    tx_id = "1"
    PendingTxs.add_registered(tx_id)

    {:ok, [{first_saved_tx_id, first_timer_ref}]} = PendingTxs.get()

    assert first_saved_tx_id == tx_id

    Process.sleep(Application.fetch_env!(:tx_watcher, :pending_time) + 50)

    {:ok, [{second_saved_tx_id, second_timer_ref}]} = PendingTxs.get()

    assert first_saved_tx_id == second_saved_tx_id
    assert first_timer_ref != second_timer_ref
  end

  test "add_registered tx_id and remove it, check that it is removed" do
    tx_id = "1"
    PendingTxs.add_registered(tx_id)

    {:ok, [{saved_tx_id, _}]} = PendingTxs.get()

    assert saved_tx_id == tx_id

    PendingTxs.remove_registered(tx_id)

    assert {:ok, []} == PendingTxs.get()
  end
end
