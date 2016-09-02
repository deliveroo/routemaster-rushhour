require 'rush_hour/redis_connection'
require 'json'
require 'hashie'

module RushHour
  # Model the metadata of a single benchmark run
  class Benchmark
    include RedisConnection

    attr_reader :id

    def initialize(options, id=nil)
      @attributes = Hashie::Mash.new.merge(DEFAULTS).merge(options)
      @id = id || SecureRandom.uuid
    end

    def save
      _redis.set(_key, @attributes.to_json)
    end

    def destroy
      EventSet.new(@id).destroy
      _redis.del(_key)
    end

    def method_missing(m, *args, &block)
      @attributes.public_send(m, *args, &block)
    end

    module ClassMethods
      include RedisConnection

      def find(id)
        data = _redis.get(_key(id))
        return unless data
        attributes = Hashie::Mash.new(JSON.parse(data))
        new(attributes, id)
      end

      private

      def _key(id)
        "benchmark:#{id}"
      end
    end
    extend ClassMethods

    private

    DEFAULTS = {
      n_events:     10_000,
      deadline:     500,
      batch_size:   100,
      topics:       1,
      queues:       1,
      send_threads: 1,
    }

    def _key
      self.class.send(:_key, id)
    end
  end
end

