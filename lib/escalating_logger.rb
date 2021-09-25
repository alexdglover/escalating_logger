# frozen_string_literal: true

require_relative './escalating_logger/version'
require 'logger'
require 'bozos_buckets'

module EscalatingLogger
  # EscalatingLogger::Logger subclasses the standard Logger class. This
  # subclass maintains the same API as Logger itself, so it can be used
  # anywhere you use Logger today
  class Logger < Logger
    DECREASE_VERBOSITY = 1
    INCREASE_VERBOSITY = -1

    attr_accessor :min_verbosity, :max_verbosity, :initial_token_count, :refill_rate,
                  :max_token_count, :triggering_log_levels, :bucket

    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable Metrics/MethodLength
    def initialize(
      logdev,
      shift_age = 0,
      shift_size = 1_048_576,
      level:                 DEBUG,
      progname:              nil,
      formatter:             nil,
      datetime_format:       nil,
      binmode:               false,
      shift_period_suffix: '%Y%m%d',
      min_verbosity:         Logger::ERROR,
      max_verbosity:         Logger::DEBUG,
      initial_token_count:   100,
      refill_rate:           1,
      max_token_count:       100,
      triggering_log_levels: [Logger::ERROR]
    )

      @triggering_log_levels = triggering_log_levels
      @max_verbosity = max_verbosity
      @min_verbosity = min_verbosity
      @initial_token_count = initial_token_count
      @refill_rate = refill_rate
      @max_token_count = max_token_count

      @bucket = BozosBuckets::Bucket.new(initial_token_count: initial_token_count,
                                         refill_rate: refill_rate, max_token_count: max_token_count)

      super(
        logdev,
        shift_age,
        shift_size,
        level: level,
        progname: progname,
        formatter: formatter,
        datetime_format: datetime_format,
        binmode: binmode,
        shift_period_suffix: shift_period_suffix
      )
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/MethodLength

    # Overrides `add` method to catch all forms of invocations. See
    # https://github.com/ruby/ruby/blob/b56c8f814e656e6a680acf2e5c96812e84af238d/lib/logger.rb#L459
    def add(severity, message = nil, progname = nil)
      # If severity is error/warning/whatever, check if the rate limit has
      # been exceeded. If so, increase verbosity. If severity check is not
      # triggered, decrease verbosity if the token bucket is full

      # Check if verbosity should be increased if logger was invoked with
      # the a triggering severity
      if @triggering_log_levels.include?(severity)
        # Increase verbosity if rate limit exceeded/bucket is empty
        increase_verbosity unless @bucket.use_tokens
      # Only attempt to decrease verbosity when the lowest severity is called
      elsif severity == level
        # Decrease verbosity if the bucket is full
        decrease_verbosity if @bucket.current_token_count == @bucket.max_token_count
      end

      # Call the superclass method with the same signature
      super
    end

    private

    def increase_verbosity
      change_verbosity(INCREASE_VERBOSITY)
    end

    def decrease_verbosity
      change_verbosity(DECREASE_VERBOSITY)
    end

    # Negative values increase verbosity, positive values decrease verbosity
    def change_verbosity(value)
      current_level = level
      reset_bucket
      case value
      when DECREASE_VERBOSITY
        next_level = [current_level + 1, @min_verbosity].min
      when INCREASE_VERBOSITY
        next_level = [current_level - 1, @max_verbosity].max
      end
      self.level = next_level
    end

    # After changing verbosity, the bucket should be reset. Otherwise
    # verbosity will change levels very quickly, instead of gradually as
    # the rate limit is continually exceeded. Note that the bucket is reset
    # using the attributes on the EscalatingLogger::Logger instance (e.g.
    # initial_token_count)
    def reset_bucket
      @bucket = BozosBuckets::Bucket.new(initial_token_count: @initial_token_count,
                                         refill_rate: @refill_rate, max_token_count: @max_token_count)
    end
  end
end
