# TxWatcher

To start your Phoenix server:

- docker-compose run --name tx_watcher_dev --rm --service-ports tx_watcher /bin/bash
- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `mix phx.server`

or

- docker-compose up
  If you do docker-compose up and you would want to bash into the container you need to delete it first!

  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To run tests:

- docker-compose run --name tx_watcher_dev --rm --service-ports tx_watcher /bin/bash
- MIX_ENV=test mix test

## Project specific setup

In the .env(I left my env there as an example.) file you need to set your own
BLOCKNATIVE_API_KEY in order to be able to receive webhooks on your own system.
The container will load in the .env file automatically.
You can use ngrok to expose your localhost.

In Blocknative you need to define the webhook in the following way:

`{host}/api/tx-webhook`

If you use postman you can get my collection for this project from here:
https://www.getpostman.com/collections/611e94d185c01c9cb4dc

If you prefer some other tool the following endpoints are available:

- `{host}/api/pending-txs` - to get the pending tx_ids - GET

- `{host}/api/watch-txs` - to send a list of tx_ids to be watched - POST, an example body would be:
  `{ "tx_ids": [ "0x58451623b621407fcd885e27250445ee4d218676733d480a14e1d80a2f0d6567" ] }`
  Make sure to remove the trailing space if you copy tx_id from the website that was given in the project description.

- `{host}/api/tx-webhook` - for the webhooks - POST request, an example body would be:
  `{ "hash": "1", "status": "pending" }`

## Notes on some decisions

I was aiming to make the system as unblockable as I could, hence the use of Task.start/3.

As you can see when a list of tx_ids are sent a Task is being started and a Success response is sent to the client.

I figured that I would rely on Blocknative as the source of truth,
and I would only have tx_ids registered once I got a webhook from Blocknative about them.

The following 2 things can happen after a webhook arrives from Blocknative:

- A pending tx
  If a webhook arrives with a tx that is pending we register it in the system as pending.
  That means that a message will be sent out to Slack that this tx has been registered.
  Furthermore it is possible that additional pending messages will be sent to Slack related to this tx_id if they are not confirmed in 2 minutes.
  This 2 minute window restarts every time until a tx is confirmed.
  The pending tx_ids can be retrieved by the client.

- A confirmed tx

  - If it is a tx that is not in the system as a pending tx we send a message to Slack that this tx is confirmed.
  - If this tx is in the system as pending, we remove it from the pending txs list and cancel its timer in order to not send any more pending messages related to this tx_id. Lastly we send a confirmed message to Slack.

There is credo and dialyzer in the project for code quality checks.

## Docker

The container is more towards local development in docker than deployment,
of course it could be easily adjusted and deployed by changing the defined environment,
but a lighter image without the dev tools would be the best for that.

## Possible improvements

In TxWatcher.ExternalRequests there is a simple retry mechanism in case requests would fail.
This system could be improved by something like what is described as Option#3 here:
https://dockyard.com/blog/2019/04/02/three-simple-patterns-for-retrying-jobs-in-elixir

Functionality wise it would be similar but it would give a more complete overview of what is happening.

Could add Logger logs to follow the flow inside the project.
More test cases would be possible around the retry mechanism.

I noticed that you can request the transactions from Blocknative that you you have subscribed to before,
which could be interesting to use when the system start.
The problem is that you don't know if those txs are completed or not, so you could show completed txs as pending.
For the same reason you can receive updates about txs that you subscribed to before you restarted the project but
they are not pending in the system.
These could be rejected after checking in our own pending list, but I opted not doing it,
because the client sent the tx_id, so the least is to give them the info we get about it.
Based on business decisions it would be entirely possible to change this.
