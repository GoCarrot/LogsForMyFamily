# frozen_string_literal: true

require 'digest'

module LogsForMyFamily
  class Logger
    attr_accessor :backends

    LEVELS = %i[
      debug
      info
      notice
      warning
      error
      critical
      alert
      emergency
      audit
    ].freeze

    def initialize
      @backends = LogsForMyFamily.configuration.backends
      @configuration = LogsForMyFamily.configuration.to_h
      @request_id = LogsForMyFamily.configuration.request_id
      @request_config = {}
      @event_id = 0
      @filter_level = 0
      @filter_percent = 1.0
      @filter_percent_on = nil
      @filter_percent_below_level = 0
    end

    def set_request(env)
      @request_config[:request_id] = @request_id.call(env)
      self
    end

    def set_request_id(id)
      @request_config[:request_id] = id
      self
    end

    def set_client_request_info(info)
      @request_config[:client_request_info] = info
      self
    end

    def request_id
      @request_config[:request_id]
    end

    def filter_level(level)
      level = LEVELS.find_index(level) if level.is_a?(Symbol)
      @filter_level = level
      self
    end

    def clear_filter_level
      @filter_level = 0
      self
    end

    def proc_for_event_data(*on)
      proc { |data| (Digest::SHA256.hexdigest(data.dig(*on)).to_i(16) % 2_147_483_647).to_f / 2_147_483_646.0 }
    end

    def filter_percentage(percent: 1.0, on: proc { rand }, below_level: 1)
      @filter_percent = percent

      below_level = LEVELS.find_index(below_level) if below_level.is_a?(Symbol)
      @filter_percent_below_level = below_level < 1 ? 1 : below_level

      @filter_percent_on = on if on.respond_to?(:call) ? on : proc_for_event_data(on)
      self
    end

    def clear_filter_percentage
      @filter_percent_on = nil
      self
    end

    LEVELS.each_with_index do |level, index|
      define_method level do |event_type, event_data|
        internal_log(index, level, event_type, event_data)
      end
    end

    private

    def internal_log(level, level_name, event_type, event_data)
      timestamp = Time.now.to_f # Do this first before filtering or any other things

      # Filter based on log level
      return unless level >= @filter_level

      event_data = { message: event_data } unless event_data.is_a?(Hash)

      merged_data = {
        pid: Process.pid,
        timestamp: timestamp,
        thread_id: Thread.current.object_id,
        event_id: @event_id,
        log_version: LogsForMyFamily::VERSION
      }
                    .merge(@configuration)
                    .merge(@request_config)
                    .merge(event_data)

      # Filter based on log-sampling
      if @filter_percent_on && level < @filter_percent_below_level
        val = @filter_percent_on.call(merged_data)
        return unless val <= @filter_percent
      end

      # Don't increment until filtering is complete
      @event_id += 1

      @backends.each do |backend|
        backend.call(level_name, event_type, merged_data)
      end
    end
  end
end
