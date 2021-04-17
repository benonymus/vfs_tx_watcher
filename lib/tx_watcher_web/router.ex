defmodule TxWatcherWeb.Router do
  use TxWatcherWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TxWatcherWeb do
    pipe_through :api

    get("/pending-txs", TxsController, :pending_txs)
    post("/watch-txs", TxsController, :watch_txs)
    post("/tx-webhook", TxsController, :tx_webhook)
  end
end
