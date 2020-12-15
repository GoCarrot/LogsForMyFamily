# frozen_string_literal: true

module LogsForMyFamily
  class Rack
    def initialize(app)
      @app = app
      @logger = LogsForMyFamily::Logger.new
    end

    def call(env)
      @app.call(env.merge({
                            'logsformyfamily.logger' => @logger.clone.set_request
                          }))
    end
  end
end
