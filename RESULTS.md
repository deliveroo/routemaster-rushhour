Benchmarking results, as of deliveroo/routemaster@98b4b95 and deliveroo/routemaster-client@6f7af94.
Runs from 2016-09-12.

# Throughput lower bound

When running a single delivery thread, the maximum throughput is around 60
event/s (15 ms/event).

This can be significanlty improved by:

- "fixing" batching of events (don't send events 1 at a time when there's a queue)
- reducing Redis roundtrips in the delivery system (e.g. memoizing queue
  parameters, like batch size and timeout; currently they're polled at every
  delivery attempt).


```
Server web dynos:   5
Server watch dynos: 1
---------------------------------------------

Sending threads:    5
Batching deadline:  500
Batch size:         100
---------------------------------------------

Events sent:        10000/10000
throughput:         211.12380950450677

Events received:    10000/10000
throughput:         58.83165579377264

Latency:        5%  5151451.0 µs
            median  54216900.0 µs
               95%  117549426.0 µs

Batch size:     5%  1.0
            median  1.0
               95%  1.0
```

# Single-topic stress test

Witch the existing setup, 4-5 watches are able to handle the throughput of 10
aggressive publishers.

Scaling seems only limited by the Redis throughput; we've observed that a
sustained 1,000 event/s throughput uses up about 20% of our test Redis instance
(RedisGreen "development" instance; non-dedicated hardware).

4 watches: batching suffers.

    Server web dynos:   10
    Server watch dynos: 4
    ---------------------------------------------

    Sending threads:    10
    Batching deadline:  500
    Batch size:         100
    ---------------------------------------------

    Events sent:        10000/10000
    throughput:         321.6313967821165

    Events received:    10000/10000
    throughput:         280.6673337380743

    Latency:        5%  536768.0 µs
                median  4907780.0 µs
                   95%  10028135.0 µs

    Batch size:     5%  1.0
                median  1.0
                   95%  1.0


5 watches: batching at 1/3 efficiency.

    Server web dynos:   10
    Server watch dynos: 5
    ---------------------------------------------

    Sending threads:    10
    Batching deadline:  500
    Batch size:         100
    ---------------------------------------------

    Events sent:        10000/10000
    throughput:         338.4237682863899

    Events received:    10000/10000
    throughput:         338.922561786854

    Latency:        5%  273711.0 µs
                median  478660.0 µs
                   95%  567632.0 µs

    Batch size:     5%  2.0
                median  37.0
                   95%  100.0

10 watches: batching at 1/8th efficiency

    Server web dynos:   10
    Server watch dynos: 10
    ---------------------------------------------

    Sending threads:    10
    Batching deadline:  500
    Batch size:         100
    ---------------------------------------------

    Events sent:        10000/10000
    throughput:         329.43204531772636

    Events received:    10000/10000
    throughput:         330.08674316514964

    Latency:        5%  242790.0 µs
                median  490006.0 µs
                   95%  559307.0 µs

    Batch size:     5%  2.0
                median  14.0
                   95%  83.0

# Latency test

With a minimal delivery deadline (1ms), we're consistently around 45ms roundtrip
time.

    Server web dynos:   10
    Server watch dynos: 4
    ---------------------------------------------

    Sending threads:    1
    Batching deadline:  1
    Batch size:         100
    ---------------------------------------------

    Events sent:        1000/1000
    throughput:         44.65217429744046

    Events received:    1000/1000
    throughput:         44.661283910084684

    Latency:        5%  20496.0 µs
                median  43944.0 µs
                   95%  81800.0 µs

    Batch size:     5%  1.0
                median  1.0
                   95%  1.0

This isn't affected by the number of delivery threads (watches) as the roundtrip
is essentially single-threaded.

    Sending threads:    1
    Batching deadline:  1
    Batch size:         100
    ---------------------------------------------

    Events sent:        1000/1000
    throughput:         45.733061880171235

    Events received:    1000/1000
    throughput:         45.728084621100976

    Latency:        5%  13128.0 µs
                median  42019.0 µs
                   95%  176797.0 µs

    Batch size:     5%  1.0
                median  1.0
                   95%  2.0

# Infrastructure usage

Under our most aggressive stress-test, resource usage remained low, opening an
opportunity for on-dyno concurrency.

The apparently "high" Puma load seems due to threading warmum (low number of
starting threads) and can be addressed with configuration.

                      avg       max
    Watch memory:     33.4MB    36.8MB
          loadavg:    0.42      0.72

    Web   memory:     103.1MB   137.3MB
          loadavg:    0.16      1.86
