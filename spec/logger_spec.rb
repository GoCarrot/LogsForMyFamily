# frozen_string_literal: true

RSpec.describe LogsForMyFamily::Logger do
  let!(:backend) { RspecLogBackend.new }
  let(:logs) { backend.logs }
  let(:last_log) { backend.last_log }

  before do
    subject.backends << backend
  end

  it 'calls the logging backend' do
    subject.info('foo', 'bar')
    expect(last_log).not_to be nil
    expect(last_log.level).to eql :info
    expect(last_log.type).to eql 'foo'
    expect(last_log.data).to include(message: 'bar')
  end

  context 'with multiple logging backends' do
    let!(:backend2) { RspecLogBackend.new }
    let(:logs2) { backend2.logs }
    let(:last_log2) { backend2.last_log }

    before do
      subject.backends << backend2
    end

    it 'calls all logging backends' do
      subject.info('foo', 'bar')

      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.type).to eql 'foo'
      expect(last_log.data).to include(message: 'bar')

      expect(last_log2).not_to be nil
      expect(last_log2.level).to eql :info
      expect(last_log2.type).to eql 'foo'
      expect(last_log2.data).to include(message: 'bar')
    end
  end

  context 'when configured with host information' do
    let(:version) { 'abcd' }
    let(:hostname) { 'somehost' }
    let(:app_name) { 'an_appname' }

    before do
      ENV['NEWRELIC_APP'] = app_name
      subject.configure_for(version: version, hostname: hostname)
    end

    it 'contains the app version' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(version: version)
    end

    it 'contains the hostname' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(hostname: hostname)
    end

    it 'contains the app name' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(app_name: app_name)
    end
  end
end
