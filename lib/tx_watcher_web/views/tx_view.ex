defmodule TxWatcherWeb.TxView do
  use TxWatcherWeb, :view

  def render("200.json", %{conn: %{assigns: %{message: message}}}) do
    %{
      meta: %{status: 200, message: message},
      errors: nil,
      data: nil
    }
  end

  def render("list_pending_txs.json", %{conn: %{assigns: %{pending_txs: pending_txs}}}) do
    %{
      meta: %{status: 200, message: "Success"},
      errors: nil,
      data: %{
        tx_ids: Enum.map(pending_txs, fn {tx_id, _} -> tx_id end)
      }
    }
  end
end
