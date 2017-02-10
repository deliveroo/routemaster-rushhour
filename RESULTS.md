Benchmarking results, as of deliveroo/routemaster@74b4d6c and deliveroo/routemaster-client@6f7af94.
Runs from 2016-12-21.


# Ingestion performance

We first configure the bus to 1 web server, 1 process, with 1 thread to estimate
how quickly the bus can ingest events.

## Baseline

Using a single sending thread, publishing events in sequence, we get a
lower-bound throughput that provides a best-case ingestiong latency estimate.

```
Bus ingestion:      1 dyno, 1 process, 1 thread
Bus delivery:       n/a
---------------------------------------------

Sending threads:    1
Batching deadline:  500
Batch size:         100
---------------------------------------------
Events sent:        1000/1000
throughput:         75.83 e/s
```

Ramping up the number of sending threads gives us a sense of the ingestion
capacity of a single ingestion thread:

```
Bus ingestion:      1 dyno, 1 process, 1 thread
Bus delivery:       n/a
---------------------------------------------

Sending threads:    10
Batching deadline:  500
Batch size:         100
---------------------------------------------
Events sent:        2000/2000
throughput:         146.23 e/s
```

Conclusions:

- nominal ingestion latency of 13ms
- nominal ingestion throughput of ~150 events/second/thread


## Scaling behaviour

Single server, multiple threads:

| Sending threads | Ingestion threads | Ingestion throughput |
|-----------------|-------------------|----------------------|
| 10              | 1                 | 146 e/s              |
| 10              | 2                 | 190                  |
| 10              | 3                 | 190                  |
| 10              | 4                 | 190                  |

Multiple servers, each with 1 process x 3 threads:

| Sending threads | Ingestion procs.  | Ingestion throughput |
|-----------------|-------------------|----------------------|
| 10              | 1                 | 146 e/s              |
| 10              | 2                 | 347                  |
| 10              | 3                 | 487                  |
| 10              | 4                 | 581                  |
| 10              | 5                 | 657                  |

Conclusions:

- ingestion scales roughly linearly with the number of ingestion processes.

# Delivery performance

We weren't able to saturate a delivery thread with default batching/deadline
settings, likely because the batch size of 100 creates a x100 ratio between the
cost of ingestion and that of delivery.

Smaller batch sizes and deadlines do impact the performance of delivery.

| Sending threads  | Batch size       | Latency (median) |
|------------------|------------------|------------------|
| 5                | 100              | 470ms            | 
| 5                | 50               | 506ms            |
| 5                | 10               | 412ms            |
| 5                | 5                | 2090ms           |
| 5                | 1                | 17000ms          |

| Sending threads  | Latency (median) | Obs. batch size
|------------------|------------------|------------------|
| 1                | 339ms            | 15               |
| 2                | 368ms            | 29               |
| 3                | 396ms            | 44               |
| 4                | 423ms            | 56               |
| 5                | 477ms            | 81               |
| 6                | 491ms            | 89               |
| 7                | 480ms            | 100              |
| 8                | 509ms            | 100              |
| 9                | 577ms            | 100              |
| 10               | 821ms            | 100              |

Conclusions:

- Assuming a standard batch size of 100, provision 1 delivery thread for every 5
  ingestion thread.
- Very small batch sizes are strongly discouraged.



# Performance at scale

Using the lessons above, we provision more resources for the bus, with a 150:50
ratio between delivery threads and ingestion threads.

Using this formation,

```
Bus ingestion:      10 servers, 5 processes, 3 threads
Bus delivery:       10 servers, 1 process,   5 threads
---------------------------------------------
Sending threads:    240
Batching deadline:  500 ms
Batch size:         100
---------------------------------------------
Events sent:        10000/10000
throughput:         2194.69 e/s

Events received:    10000/10000
throughput:         1069.73 e/s

Latency:        5%  652277.0 µs
            median  6092899.0 µs
               95%  11064143.0 µs

Batch size:     5%  100
            median  100
               95%  100
```

At 2200 event/s throughput, Redis CPU usage hovered around 30%.


# Memory usage

At rest: 467K.

| Batch size    | Queued events | Memory usage (MB)|
|---------------|---------------|------------------|
| 100           | 10k           | 4.74             |
| 100           | 20k           | 6.06             |
| 100           | 30k           | 7.36             |
| 100           | 40k           | 8.67             |
| 100           | 50k           | 9.97             |
| 100           | 60k           | 11.28            |
| 100           | 70k           | 12.58            |


| Batch size    | Queued events | Memory usage (MB)|
|---------------|---------------|------------------|
| 50            | 10k           | 4.88             |
| 50            | 20k           | 6.32             |
| 50            | 30k           | 7.74             |
| 50            | 40k           | 10.06            |
| 50            | 50k           | 11.56            |
| 50            | 60k           | 13.07            |
| 50            | 70k           | 13.48            |


Conclusions:

- With normal batch sizes (20-200 events), provision 250MB of Redis memory per
  1M events that might be queued at peak.






