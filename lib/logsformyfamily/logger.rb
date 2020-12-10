# frozen_string_literal: true

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
      @backends = []
      @host_config = {}
      @request_config = {}
      @event_id = 0
      @filter_level = 0
    end

    def configure_for(version: nil, hostname: `hostname`.strip, app_name: ENV['NEWRELIC_APP'])
      @host_config = {
        version: version,
        hostname: hostname,
        app_name: app_name
      }
      self
    end

    def set_request(client_request_info: {}, request_id: ENV['core_app.request_id'])
      @request_config = {
        request_id: request_id,
        client_request_info: client_request_info
      }
      self
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

    LEVELS.each_with_index do |level, index|
      define_method level do |event_type, event_data|
        internal_log(index, level, event_type, event_data)
      end
    end

    def internal_log(level, level_name, event_type, event_data)
      timestamp = Time.now.to_f # Do this first before filtering or any other things

      # Filter based on log level
      return unless level >= @filter_level

      event_data = { message: event_data } unless event_data.is_a?(Hash)

      merged_data = {
        pid: Process.pid,
        timestamp: timestamp,
        thread_id: Thread.current.object_id,
        event_id: @event_id
      }
                    .merge(@host_config)
                    .merge(@request_config)
                    .merge(event_data)


      # Don't increment until filtering is complete
      @event_id += 1

      @backends.each do |backend|
        backend.call(level_name, event_type, merged_data)
      end
    end
  end
end
