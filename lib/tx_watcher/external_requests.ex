defmodule TxWatcher.ExternalRequests do
  @moduledoc """
  Context for external calls
  """
  @http_client Application.compile_env!(:tx_watcher, :http_client)
  @slack_webhook_url Application.compile_env!(:tx_watcher, :slack_webhook_url)
  @blocknative_api_url Application.compile_env!(:tx_watcher, :blocknative_api_url)
  @blocknative_api_key Application.compile_env!(:tx_watcher, :blocknative_api_key)
  @retry_limit 3
  @retry_wait 1000

  @spec send_msg_to_slack(String.t()) :: {:ok, pid()}
  def send_msg_to_slack(msg) do
    Task.start(__MODULE__, :send_msg_to_slack_logic, [msg])
  end

  @spec send_msg_to_slack_logic(String.t(), integer()) :: :ok
  def send_msg_to_slack_logic(msg, retry \\ 1)

  def send_msg_to_slack_logic(msg, retry) when retry <= @retry_limit do
    @http_client.request(
      :post,
      {@slack_webhook_url, [], 'application/json',
       Jason.encode!(%{
         text: msg
       })},
      [],
      []
    )
    |> case do
      {:ok, _} ->
        :ok

      _ ->
        sleep(retry)

        send_msg_to_slack_logic(msg, retry + 1)
    end
  end

  def send_msg_to_slack_logic(_, _), do: :ok

  @spec register_txs(list(String.t())) :: :ok
  def register_txs(tx_ids) do
    Enum.each(tx_ids, fn tx_id ->
      Task.start(__MODULE__, :register_tx_logic, [tx_id])
    end)
  end

  @spec register_tx_logic(String.t(), integer()) :: :ok
  def register_tx_logic(tx_id, retry \\ 1)

  def register_tx_logic(tx_id, retry) when retry <= @retry_limit do
    @http_client.request(
      :post,
      {@blocknative_api_url, [], 'application/json',
       Jason.encode!(%{
         apiKey: @blocknative_api_key,
         hash: tx_id,
         blockchain: "ethereum",
         network: "main"
       })},
      [],
      []
    )
    |> case do
      {:ok, _} ->
        :ok

      _ ->
        sleep(retry)
        register_tx_logic(tx_id, retry + 1)
    end
  end

  def register_tx_logic(_, _), do: :ok

  # we don't need to sleep on the last turn
  @spec sleep(integer()) :: :ok
  defp sleep(retry) when retry < @retry_limit, do: Process.sleep(@retry_wait * retry)
  defp sleep(_), do: :ok
end
