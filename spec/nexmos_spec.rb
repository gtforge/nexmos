require 'spec_helper'
describe ::Nexmos do
  subject{ ::Nexmos }

  before(:each) do
    described_class.reset!
  end

  context '#reset!' do
    describe '#user_agent' do
      subject { super().user_agent }
      it { is_expected.to eq("Nexmos v#{::Nexmos::VERSION}") }
    end

    describe '#api_key' do
      subject { super().api_key }
      it { is_expected.to be_nil }
    end

    describe '#api_secret' do
      subject { super().api_secret }
      it { is_expected.to be_nil }
    end

    describe '#logger' do
      subject { super().logger }
      it { is_expected.to be_kind_of(::Logger) }
    end
  end

  context '#setup' do

    context 'single call' do
      it 'should set user_agent' do
        subject.setup do |c|
          c.user_agent = 'Test1245'
        end
        expect(subject.user_agent).to eq('Test1245')
      end

      it 'should set logger' do
        newlogger = ::Logger.new(STDERR)
        subject.setup do |c|
          c.logger = newlogger
        end
        expect(subject.logger).to eq(newlogger)
      end

      it 'should set api_key' do
        subject.setup do |c|
          c.api_key = 'test-api-key'
        end
        expect(subject.api_key).to eq('test-api-key')
      end

      it 'should set api_secret' do
        subject.setup do |c|
          c.api_secret = 'test-api-secret'
        end
        expect(subject.api_secret).to eq('test-api-secret')
      end

    end

    context 'double call' do
      it 'should not accept running setup more then once' do
        subject.setup do |c|
          c.api_key = 'test-api-key'
        end
        subject.setup do |c|
          c.api_key = 'test-api-key2'
        end
        expect(subject.api_key).to eq('test-api-key')
      end
    end
  end

end
