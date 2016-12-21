require 'rush_hour/redis_connection'
require 'securerandom'

module RushHour
  class EventSet
    include RedisConnection

    def initialize(id = nil)
      @id = id || SecureRandom.uuid
    end

    def destroy
      [_key_sent, _key_received, _key_latency, _key_batches].each do |key|
        _redis.del key
      end
    end

    def mark_sent(idx)
      _redis.zadd(_key_sent, _now, idx)
      self
    end

    def mark_received(idx)
      sent_at = _redis.zscore(_key_sent, idx)
      _redis.zadd(_key_received, _now, idx)
      _redis.zadd(_key_latency, _now-sent_at, idx) if sent_at
      self
    end

    def mark_batch(size)
      _redis.zadd(_key_batches, size, _now)
    end

    def count_sent
      _redis.zcard(_key_sent)
    end

    def count_received
      _redis.zcard(_key_received)
    end

    def throughput_sent
      _throughput(_key_sent).round(2)
    end

    def throughput_received
      _throughput(_key_received).round(2)
    end

    def latency(percentile)
      count = _redis.zcard(_key_latency)
      return 0 unless count
      position = (percentile * count).to_i
      _score_for(_key_latency, position)
    end

    def batch_size(percentile)
      count = _redis.zcard(_key_batches)
      return 0 unless count
      position = (percentile * count).to_i
      _score_for(_key_batches, position).round
    end

    private

    def _throughput(key)
      first_at = _score_for(key, 0)
      last_at  = _score_for(key, -1)
      return 0 unless first_at && last_at && first_at != last_at
      1e6 * count_sent / (last_at - first_at)
    end

    def _score_for(key, position)
      res = _redis.zrange(key, position, position, with_scores: true)
      res&.first&.last
    end

    def _now
      (Time.now.utc.to_f * 1e6).to_i
    end

    def _key_prefix
      "event_set:#{@id}"
    end

    def _key_sent
      "#{_key_prefix}:sent"
    end

    def _key_received
      "#{_key_prefix}:received"
    end

    def _key_latency
      "#{_key_prefix}:latency"
    end

    def _key_batches
      "#{_key_prefix}:batches"
    end
  end
end
