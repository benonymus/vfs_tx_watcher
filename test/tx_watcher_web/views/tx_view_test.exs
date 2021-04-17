defmodule TxWatcherWeb.TxViewTest do
  use TxWatcherWeb.ConnCase
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 200.json" do
    message = "test message"

    assert render(TxWatcherWeb.TxView, "200.json", %{conn: %{assigns: %{message: message}}}) == %{
             meta: %{status: 200, message: message},
             errors: nil,
             data: nil
           }
  end

  test "renders list_pending_txs.json" do
    pending_txs = [{"1", nil}, {"2", nil}]

    result_tax_ids = Enum.map(pending_txs, fn {tx_id, _} -> tx_id end)

    assert render(TxWatcherWeb.TxView, "list_pending_txs.json", %{
             conn: %{assigns: %{pending_txs: pending_txs}}
           }) == %{
             meta: %{status: 200, message: "Success"},
             errors: nil,
             data: %{
               tx_ids: result_tax_ids
             }
           }
  end
end
