require 'rush_hour/benchmark'
require 'rush_hour/publish_job'
require 'sidekiq/api'

# Benchmarking interface
module RushHour
  class Controller
    def initialize(**options)
      @bm = Benchmark.new(options)
    end

    def start
      @bm.save
      Sidekiq::Queue.all.each(&:clear)
      PublishJob.perform_async(id: @bm.id)
      self
    end

    def finish
      @bm.destroy
    end

    def report
      report = []
      n_sent = _set.count_sent
      n_recv = _set.count_received

      puts <<~EOF
        Sending threads:    #{@bm.send_threads}
        Batching deadline:  #{@bm.deadline}
        Batch size:         #{@bm.batch_size}

        ---------------------------------------------

        Events sent:        #{n_sent}/#{@bm.n_events}
        throughput:         #{_set.throughput_sent}

        Events received:    #{n_recv}/#{@bm.n_events}
        throughput:         #{_set.throughput_received}

        Latency:        5%  #{_set.latency(0.05)} µs
                    median  #{_set.latency(0.50)} µs
                       95%  #{_set.latency(0.95)} µs

        Batch size:     5%  #{_set.batch_size(0.05)}
                    median  #{_set.batch_size(0.50)}
                       95%  #{_set.batch_size(0.95)}
      EOF
    end

    private

    def _set
      @_set ||= EventSet.new(@bm.id)
    end
  end
end
