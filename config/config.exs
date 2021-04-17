# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :tx_watcher, TxWatcherWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JxHKhHzVBjbLW92LnE9wptlFKJgEudlCieIqf8pyOWFR3hIbY5wVRDPcWLC2/F3+",
  render_errors: [view: TxWatcherWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: TxWatcher.PubSub,
  live_view: [signing_salt: "bKtlp7Sy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tx_watcher,
  http_client: :httpc,
  blocknative_api_url: 'https://api.blocknative.com/transaction',
  blocknative_api_key: "fdc669c2-86de-4d36-aee2-1682f66b2a43",
  slack_webhook_url:
    "https://hooks.slack.com/services/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",
  pending_time: 1_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
