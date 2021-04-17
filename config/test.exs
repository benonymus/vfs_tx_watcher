use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tx_watcher, TxWatcherWeb.Endpoint,
  http: [port: 4002],
  server: false

config :tx_watcher,
  http_client: TxWatcherWeb.MockHttpClient,
  blocknative_api_url: 'test_api_url',
  blocknative_api_key: "test_api_key",
  slack_webhook_url: "test_slack_webhook_url",
  pending_time: 2_000

# Print only warnings and errors during test
config :logger, level: :warn
