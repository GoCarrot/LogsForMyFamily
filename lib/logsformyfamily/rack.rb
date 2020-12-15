# frozen_string_literal: true

module LogsForMyFamily
  class Rack
    def initialize(app)
      @app = app
      @logger = LogsForMyFamily::Logger.new
    end

    def call(env)
      env['logsformyfamily.logger'] = @logger.clone.set_request(env)
      @app.call(env)
    end
  end
end
