defmodule TxWatcherWeb.TxsControllerTest do
  use TxWatcherWeb.ConnCase

  describe "insert tax_ids" do
    test "host/api/watch-txs", %{conn: conn} do
      conn =
        conn
        |> post("/api/watch-txs", %{
          "tx_ids" => ["1", "2", "3"]
        })

      json_response(conn, 200)
    end
  end

  describe "get pending tax_ids" do
    test "host/api/pending-txs", %{conn: conn} do
      conn =
        conn
        |> get("/api/pending-txs")

      json_response(conn, 200)
    end
  end

  describe "catch webhook" do
    test "host/api/tx-webhook", %{conn: conn} do
      conn =
        conn
        |> post("/api/tx-webhook", %{
          "hash" => "1",
          "status" => "pending"
        })

      response(conn, 200)
    end
  end
end
