require 'redis'

module RushHour
  module RedisConnection
    def self.redis
      @_redis ||= Redis.new(url: ENV.fetch('REDIS_URL'))
    end

    protected

    def _redis
      RedisConnection.redis
    end
  end
end
