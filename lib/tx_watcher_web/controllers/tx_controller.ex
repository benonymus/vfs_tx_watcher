defmodule TxWatcherWeb.TxsController do
  @moduledoc """
  TxsController controller
  """
  use TxWatcherWeb, :controller

  alias TxWatcherWeb.TxView
  alias TxWatcher.{ExternalRequests, PendingTxs}

  @doc """
  List pending txs
  """
  def pending_txs(conn, _params) do
    {:ok, pending_txs} = PendingTxs.get()

    conn
    |> put_status(200)
    |> put_view(TxView)
    |> render("list_pending_txs.json", pending_txs: pending_txs)
  end

  @doc """
  Add txs to be watched
  """
  def watch_txs(conn, %{"tx_ids" => tx_ids}) do
    Task.start(ExternalRequests, :register_txs, [tx_ids])

    conn
    |> put_status(200)
    |> put_view(TxView)
    |> render("200.json", message: "Received txs!")
  end

  @doc """
  tx webhook event handler
  """
  def tx_webhook(conn, params) do
    Task.start(__MODULE__, :process_tx_event, [params])

    conn
    |> send_resp(200, "OK")
  end

  def process_tx_event(%{"hash" => tx_id, "status" => status})
      when status == "pending" do
    PendingTxs.add_registered(tx_id)
  end

  def process_tx_event(%{"hash" => tx_id, "status" => status})
      when status == "confirmed" do
    PendingTxs.remove_registered(tx_id)
  end

  def process_tx_event(_), do: :ok
end
