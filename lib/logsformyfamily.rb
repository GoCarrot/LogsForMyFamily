# frozen_string_literal: true

require 'logsformyfamily/logger'
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
    attr_accessor :version, :hostname, :app_name, :backends

    def initialize
      @version = `git rev-parse --short HEAD`.chomp
      @hostname = `hostname`.strip
      @app_name = ENV['NEWRELIC_APP']
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
