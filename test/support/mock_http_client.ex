defmodule TxWatcherWeb.MockHttpClient do
  @moduledoc """
  Mock of the responses of the http calls
  """
  @blocknative_api_url Application.compile_env!(:tx_watcher, :blocknative_api_url)
  @slack_webhook_url Application.compile_env!(:tx_watcher, :slack_webhook_url)

  def request(_, {@blocknative_api_url, _, _, _}, _, _) do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, [], '{"msg":"success"}'}}
  end

  def request(_, {@slack_webhook_url, _, _, _}, _, _) do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, [], 'ok'}}
  end
end
