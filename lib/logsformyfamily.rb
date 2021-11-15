# frozen_string_literal: true

require 'logsformyfamily/logger'
require 'logsformyfamily/rack'
require 'logsformyfamily/sidekiq'
require 'logsformyfamily/version'

module LogsForMyFamily
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.logger
    Thread.current.thread_variable_get(:'logsformyfamily.logger')
  end

  def self.logger=(val)
    Thread.current.thread_variable_set(:'logsformyfamily.logger', val)
  end

  module LocalLogger
    def logger
      @logger ||= LogsForMyFamily.logger || LogsForMyFamily::Logger.new
    end
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :version, :hostname, :app_name, :backends, :request_id

    def initialize
      @version = `command -v git && git rev-parse --short HEAD`.chomp
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
