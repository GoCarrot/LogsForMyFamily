# frozen_string_literal: true

require 'logsformyfamily/logger'
require 'logsformyfamily/rack'
require 'logsformyfamily/version'

module LogsForMyFamily
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :version, :hostname, :app_name, :backends, :request_id

    def initialize
      @version = `git rev-parse --short HEAD`.chomp
      @hostname = `hostname`.strip
      @app_name = ENV['NEWRELIC_APP']
      @backends = []
      @request_id = proc { |env| env['core_app.request_id'] }
    end

    def to_h
      {
        version: @version,
        hostname: @hostname,
        app_name: @app_name
      }
    end
  end

  self.configuration ||= Configuration.new
end
