# frozen_string_literal: true

require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'logsformyfamily'

class RspecLogBackend
  attr_accessor :logs, :last_log

  LogEntry = Struct.new(:level, :type, :data) do
  end

  def initialize
    @logs = []
    @last_log = nil
  end

  def call(level_name, event_type, event_data)
    @last_log = LogEntry.new(level_name, event_type, event_data)
    @logs << @last_log
  end
end

test_configuration_values = {
  version: 'abcd',
  hostname: 'somehost',
  app_name: 'an_appname'
}

LogsForMyFamily.configure do |config|
  config.version = test_configuration_values[:version]
  config.hostname = test_configuration_values[:hostname]
  config.app_name = test_configuration_values[:app_name]
end

RSpec.configure do |config|
  config.before(:example) { @test_configuration_values = test_configuration_values }

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
