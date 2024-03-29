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

  context 'with only event_type provided' do
    it 'sets event_type to log_message and puts the message under a message key in data' do
      subject.info('foo')
      expect(last_log).to have_attributes(
        level: :info,
        type: :log_message,
        data: a_hash_including(message: 'foo')
      )
    end
  end

  it 'contains the configuration values' do
    subject.info('foo', 'bar')
    expect(last_log).not_to be nil
    expect(last_log.level).to eql :info
    expect(last_log.data).to include(@test_configuration_values)
  end

  describe '#set_request' do
    let(:request_id) { 'arequestid' }

    before do
      subject.set_request({ 'core_app.request_id' => request_id })
    end

    it 'contains the request_id' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(request_id: request_id)
    end
  end

  describe '#set_request_id' do
    let(:request_id) { 'arequestid' }

    before do
      subject.set_request_id(request_id)
    end

    it 'contains the request_id' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(request_id: request_id)
    end
  end

  describe '#set_client_request_info' do
    let(:client_request_info) { { brew: :haha } }

    before do
      subject.set_client_request_info client_request_info
    end

    it 'contains the client request info' do
      subject.info('foo', 'bar')
      expect(last_log).not_to be nil
      expect(last_log.level).to eql :info
      expect(last_log.data).to include(client_request_info: hash_including(client_request_info))
    end
  end

  describe '#filter_level' do
    LogsForMyFamily::Logger::LEVELS.each_with_index do |level, index|
      context "when log level based filtering is :#{level}" do
        before do
          subject.filter_level level
        end

        it "provides the correct level on read" do
          expect(subject.level).to eq level
        end

        if index > 0
          LogsForMyFamily::Logger::LEVELS[0..(index - 1)].each do |inner_level|
            it "does not log messages with level: #{inner_level}" do
              subject.send(inner_level, 'foo', 'bar')
              expect(last_log).to be nil
            end
          end
        end

        LogsForMyFamily::Logger::LEVELS[index..-1].each do |inner_level|
          it "logs messages with level: #{inner_level}" do
            subject.send(inner_level, 'foo', 'bar')
            expect(last_log).not_to be nil
            expect(last_log.level).to eql inner_level
            expect(last_log.type).to eql 'foo'
            expect(last_log.data).to include(message: 'bar')
          end
        end

        if level == :audit
          describe '#clear_filter_level' do
            before do
              subject.clear_filter_level
            end
            LogsForMyFamily::Logger::LEVELS.each do |inner_level|
              it "logs messages with level: #{inner_level}" do
                subject.send(inner_level, 'foo', 'bar')
                expect(last_log).not_to be nil
                expect(last_log.level).to eql inner_level
                expect(last_log.type).to eql 'foo'
                expect(last_log.data).to include(message: 'bar')
              end
            end
          end
        end
      end
    end
  end

  describe '#filter_percentage' do
    context 'when logging 25% of calls with stubbed values: [0.1, 0.2, 0.3]' do
      before do
        test_values = [0.1, 0.2, 0.3]
        subject.filter_percentage(percent: 0.25, on: proc { test_values.slice!(0) })
      end

      it 'logs the first two calls, but not the third' do
        subject.debug('foo', 'bar')
        expect(logs.count).to be 1

        subject.debug('foo', 'bar')
        expect(logs.count).to be 2

        subject.debug('foo', 'bar')
        expect(logs.count).to be 2
      end
    end

    context 'when logging a percentage calls below :error' do
      class FilterFunctor
        attr_accessor :called

        def initialize
          @called = false
        end

        def call(_arg)
          @called = true
          1.0
        end
      end

      let(:functor) { FilterFunctor.new }

      before do
        subject.filter_percentage(percent: 0.25, on: functor, below_level: :error)
      end

      it 'does not test to see if it should log error' do
        subject.error('foo', 'bar')
        expect(logs.count).to be 1
        expect(functor.called).to be false
      end

      it 'tests before logging levels below error' do
        subject.warning('foo', 'bar')
        expect(logs.count).to be 0
        expect(functor.called).to be true
      end

      describe '#clear_filter_percentage' do
        before do
          subject.clear_filter_percentage
        end

        it 'does not test to see if it should log debug' do
          subject.debug('foo', 'bar')
          expect(logs.count).to be 1
          expect(functor.called).to be false
        end
      end
    end
  end

  describe '#proc_for_event_data' do
    context 'when provided a single symbol' do
      let(:proc) { subject.proc_for_event_data(:foo) }
      let(:data) { { foo: 'asdf' } }

      it { expect(proc).to be_a(Proc) }

      it { expect(proc.call(data)).to be_a(Numeric) }
      it { expect(proc.call(data)).to be >= 0.0 }
      it { expect(proc.call(data)).to be <= 1.0 }
    end

    context 'when provided multiple symbols' do
      let(:proc) { subject.proc_for_event_data(:foo, :bar) }
      let(:data) { { foo: { bar: 'xyzw' } } }

      it { expect(proc).to be_a(Proc) }

      it { expect(proc.call(data)).to be_a(Numeric) }
      it { expect(proc.call(data)).to be >= 0.0 }
      it { expect(proc.call(data)).to be <= 1.0 }
    end
  end
end
