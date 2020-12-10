# frozen_string_literal: true

RSpec.describe LogsForMyFamily::Logger do
  let!(:backend) { RspecLogBackend.new }
  let(:logs) { backend.logs }
  let(:last_log) { backend.last_log }

  before do
    subject.backends << backend
  end

  it 'logs to the thing' do
    subject.info('foo', 'bar')
    expect(last_log).not_to be nil
  end
end
