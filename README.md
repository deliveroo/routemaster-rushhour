## Routemaster Rush Hour

A benchmarking tool for Routemaster.

## Configuration

Either edit `.env` (if running locally) or set the corresponding variables (if
running on e.g. Heroku).

## Usage

Fire up the server with:

```
$ foreman start -m web=1,worker=5
```

`worker=5` controls the maximum number of event-sending threads you can run.

Run a console:

```
$ ./console
```

Create a benchmark, and run it:

```
> c = RushHour::Controller.new(send_threads: 5)
> c.start
```

Controller options:

- `send_threads`: how many event async sending threads to use (capped by the worker count)
- `n_events`: how many events to send in total.
- `deadline`: when subscribing, what maximum event age to tell Routemaster to
  use before delivery (for batching purposes).
- `batch_size`: maximum number of events in a batch.

