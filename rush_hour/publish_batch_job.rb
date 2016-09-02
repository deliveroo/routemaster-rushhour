require 'sidekiq'
# require 'sidekiq/api'
# require 'sidekiq/worker'
require 'rush_hour/logging'
require 'rush_hour/bus_connection'
require 'rush_hour/benchmark'
require 'rush_hour/event_set'

module RushHour
  # Send events to the bus
  class PublishBatchJob
    include Sidekiq::Worker
    include Logging
    include BusConnection

    def perform(options)
      id = options.fetch('id')
      start = options.fetch('start')

      bm = Benchmark.find(id)
      raise 'not found' if bm.nil?
      set = EventSet.new(bm.id)

      end_idx = start + bm.n_events / bm.send_threads
      _log "sending events #{start} to #{end_idx - 1}"

      (start...end_idx).each do |idx|
        resource_url = "https://#{_hostname}/#{bm.id}/#{idx}"
        set.mark_sent(idx)
        _bus.noop(_topic, resource_url)
        $stderr.puts("sent event #{idx} for benchmark #{bm.id}")
      end
    end

    private

    def _topic
      'rush_hour'
    end

    def _hostname
      ENV.fetch('HOSTNAME')
    end
  end
end
