# frozen_string_literal: true

module LogsForMyFamily
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      logger = LogsForMyFamily::Logger.new.set_request(env)
      LogsForMyFamily.logger = logger
      @app.call(env)
    end
  end
end
