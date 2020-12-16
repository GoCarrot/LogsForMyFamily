# frozen_string_literal: true

module LogsForMyFamily
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      Thread.current.thread_variable_set('logsformyfamily.logger', LogsForMyFamily::Logger.new.set_request(env))
      @app.call(env)
    end
  end
end
