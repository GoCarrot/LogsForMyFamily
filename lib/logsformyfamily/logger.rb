# frozen_string_literal: true

module LogsForMyFamily
  class Logger
    attr_accessor :backends

    def initialize
      @backends = []
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

    def internal_log(level, level_name, event_type, event_data)
      # TODO: filter based on level
      # TODO: sampling based filtering
      @backends.each do |backend|
        backend.call(level_name, event_type, event_data)
      end
    end
  end
end
