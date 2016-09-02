require 'sidekiq'
# require 'sidekiq/api'
# require 'sidekiq/worker'
require 'rush_hour/logging'
require 'rush_hour/bus_connection'
require 'rush_hour/benchmark'
require 'rush_hour/publish_batch_job'

module RushHour
  # Send events to the bus
  class PublishJob
    include Sidekiq::Worker
    include Logging
    include BusConnection

    def perform(options)
      bm = Benchmark.find(options.fetch('id'))
      raise 'not found' if bm.nil?

      _log "resetting bus subscriptions"
      _bus.unsubscribe
      _bus.subscribe(
        topics:   [_topic],
        callback: "https://#{_hostname}/events",
        uuid:     ENV.fetch('BUS_UUID'),
        timeout:  bm.deadline,
        max:      100,
      )

      bm.send_threads.times do |k|
        _log "scheduling sending thread #{k}"
        PublishBatchJob.perform_async(id: bm.id, start: k * bm.n_events / bm.send_threads)
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
