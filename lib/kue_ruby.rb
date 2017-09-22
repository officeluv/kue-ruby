require 'json'
require 'time'
require 'redis'

# Interface with the Automattic Kue redis store
class KueRuby
  attr_reader :redis, :prefix

  # Create a new client instance
  #
  # @param Hash options
  # @option options Redis :redis an instance of `redis`
  # @option options [String] :prefix namespace in redis (default is q)
  #
  # @return [KueRuby] a new kue client instance
  def initialize(options = {})
    @redis = options[:redis]
    @prefix = options[:prefix] ? options[:prefix] : 'q'
    super()
  end

  # Create FIFO id for zset to preserve order
  #
  # @param Integer id
  #
  # @return String
  def create_fifo(id = 1)
    id_len = id.to_s.length.to_s
    len = 2 - id_len.length
    while len > 0
      id_len = '0' + id_len
      len -= 1
    end
    id_len.to_s + '|' + id.to_s
  end

  # Enqueue a job
  #
  # @param Hash options
  # @option options String :type name of the queue for the job
  # @option options Hash :data hash of job data
  # @option options [Integer] :max_attempts max attempts for the job
  # @option options [Integer] :priority default is 0/normal
  #
  # @return [KueJob] a new kue job
  def create_job(options = {})
    raise(ArgumentError, ':type String required', caller) unless options[:type]
    raise(ArgumentError, ':data Hash required', caller) unless options[:data]
    job = KueJob.new
    job.type = options[:type]
    job.data = options[:data]
    job.priority = options[:priority] ? options[:priority] : 0
    job.max_attempts = options[:max_attempts] ? options[:max_attempts] : 1
    job.state = 'inactive'
    job.created_at = Time.now
    job.backoff = { delay: 60 * 1000, type: 'exponential' }
    job.id = @redis.incr "#{@prefix}.ids"
    job.zid = create_fifo job.id
    @redis.sadd "#{@prefix}:job:types", job.type
    job.save self
    @redis.zadd("#{@prefix}:jobs", job.priority, job.zid)
    @redis.zadd("#{@prefix}:jobs:inactive", job.priority, job.zid)
    @redis.zadd("#{@prefix}:jobs:#{job.type}:inactive", job.priority, job.zid)
    @redis.lpush("#{@prefix}:#{job.type}:jobs", 1)
    job
  end

  # Job record from Automattic Kue redis store
  class KueJob
    attr_accessor :max_attempts, :backoff, :type, :delay,
                  :created_at, :updated_at, :promote_at,
                  :data, :state, :priority, :type, :id, :zid

    def initialize
      self.delay = 0
      super()
    end

    # Save job data to redis kue
    #
    # @param KueRuby KueRuby instance with redis connection
    #
    # @return [KueJob]
    def save(kue)
      kue.redis.hmset(
        "#{kue.prefix}:job:#{id}",
        'max_attempts',   max_attempts.to_i,
        'backoff',        backoff.to_json,
        'type',           type,
        'created_at',     (created_at.to_f * 1000).to_i,
        'updated_at',     (Time.now.to_f * 1000).to_i,
        'promote_at',     (Time.now.to_f * 1000).to_i + delay,
        'priority',       priority.to_i,
        'data',           data.to_json,
        'state',          state
      )
      self
    end
  end
end
