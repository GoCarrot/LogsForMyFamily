# frozen_string_literal: true

module LogsForMyFamily
  class Logger
    attr_accessor :backends

    def initialize
      @backends = []
      @host_config = {}
    end

    %i[
      debug
      info
      notice
      warning
      error
      critical
      alert
      emergency
      audit
    ].each_with_index do |level, index|
      define_method level do |event_type, event_data|
        internal_log(index, level, event_type, event_data)
      end
    end

    def internal_log(_level, level_name, event_type, event_data)
      timestamp = Time.now.to_f # Do this first before filtering or any other things

      # TODO: filter based on level
      # TODO: sampling based filtering

      event_data = { message: event_data } unless event_data.is_a?(Hash)

      merged_data = {
        pid: Process.pid,
        timestamp: timestamp,
        thread_id: Thread.current.object_id
      }
                    .merge(@host_config)
                    .merge(event_data)

      @backends.each do |backend|
        backend.call(level_name, event_type, merged_data)
      end
    end
  end
end