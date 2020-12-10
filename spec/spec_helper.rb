# frozen_string_literal: true

require 'bundler/setup'
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

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
