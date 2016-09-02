require 'uri'
require 'rush_hour/event_set'

module RushHour
  # Handle event reception
  class EventHandler
    def initialize
      @_event_sets = {}
    end

    def on_events_received(events)
      id = nil
      events.each do |event|
        *_, id, idx = URI.parse(event['url']).path.split('/')
        raise "bad event '#{event.inspect}'" unless id && idx
        _event_set(id).mark_received(idx)
        $stderr.puts "received event #{idx} for benchmark #{id}"
      end
      _event_set(id).mark_batch(events.length)
      $stderr.puts "received #{events.length} events"
    end

    private

    def _event_set(id)
      @_event_sets[id] ||= EventSet.new(id)
    end
  end
end
