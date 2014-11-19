require 'spec_helper'
describe ::Nexmos::Base do

  let(:webmock_default_headers) do
    {
      :headers => {
        'Accept'          => 'application/json',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'      => ::Nexmos.user_agent
      }
    }
  end

  before(:each) do
    ::Nexmos.reset!
  end

  context 'class' do
    subject { described_class }
    let(:default_faraday_options) do
      {
        :url     => 'https://rest.nexmo.com',
        :headers => {
          :accept     => 'application/json',
          :user_agent => ::Nexmos.user_agent
        }
      }
    end

    describe '#faraday_options' do
      subject { super().faraday_options }
      it { is_expected.to eq(default_faraday_options) }
    end

    describe '#connection' do
      subject { super().connection }
      it { is_expected.to be_kind_of(::Faraday::Connection) }
    end

    context 'faraday_options' do
      it 'should have custom user agent' do
        ::Nexmos.setup do |c|
          c.user_agent = 'test user agent'
        end
        default_faraday_options[:headers][:user_agent] = 'test user agent'
        expect(subject.faraday_options).to eq(default_faraday_options)
      end
    end

    context 'define_api_calls' do
      it 'should call define_method' do
        ::Nexmos.apis[:account].keys.each do |k|
          expect(subject).to receive(:define_method).with(k)
        end
        subject.define_api_calls(:account)
      end

      it 'should define dynamic method and call make_api_call inside' do
        subject.define_api_calls(:account)
        instance = subject.new('test_key', 'test_secret')
        expect(instance).to receive(:make_api_call).with(::Nexmos.apis[:account][:get_balance], {})
        instance.get_balance
      end
    end

  end

  context 'instance' do
    subject { ::Nexmos::Base.new('test_api', 'test_secret') }
    context 'new' do
      it 'should raise on empty api_key' do
        expect { ::Nexmos::Base.new('', 'test_secret') }.to raise_error('api_key should be set')
      end
      it 'should raise on empty api_secret' do
        expect { ::Nexmos::Base.new('test_key', '') }.to raise_error('api_secret should be set')
      end
      it 'should set default_params with values from ::Nexmos module' do
        ::Nexmos.setup do |c|
          c.api_key    = 'default_key'
          c.api_secret = 'default_secret'
        end
        instance = ::Nexmos::Base.new
        expect(instance.instance_variable_get('@default_params')).to eq({ 'api_key' => 'default_key', 'api_secret' => 'default_secret' })
      end
      it 'should set default_params with custom api key and secret' do
        instance = ::Nexmos::Base.new('test_key', 'test_secret')
        expect(instance.instance_variable_get('@default_params')).to eq({ 'api_key' => 'test_key', 'api_secret' => 'test_secret' })
      end
    end

    describe '#connection' do
      subject { super().connection }
      it { is_expected.to be_kind_of(::Faraday::Connection) }
    end

    context 'make_api_call' do

      before(:each) do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret").
          with(:headers => { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => ::Nexmos.user_agent }).
          to_return(:status => 200, :body => { 'key' => 'value' }.to_json, :headers => { 'Content-Type' => 'application/json' })
      end

      let(:api_params_without_required) do
        {
          :method => :get,
          :url    => '/test/url'
        }
      end

      let(:api_params_with_required) do
        {
          :method   => :get,
          :url      => '/test/url',
          :required => %w(key1 key2)
        }
      end

      it 'should call check_required_params' do
        expect(subject).to receive(:check_required_params)
        subject.make_api_call(api_params_with_required)
      end

      it 'should raise if all required params missing' do
        expect { subject.make_api_call(api_params_with_required) }.to raise_error('key1,key2 params required')
      end

      it 'should raise if some required params missing' do
        expect { subject.make_api_call(api_params_with_required, { :key1 => 'val' }) }.to raise_error('key2 params required')
      end

      it 'should call normalize_params' do
        expect(subject).to receive(:normalize_params).and_call_original
        subject.make_api_call(api_params_without_required)
      end

      it 'should not call camelize_params' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret&test_call=value").
          with(webmock_default_headers).
          to_return(:status => 200, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        expect(subject).not_to receive(:camelize_params)
        subject.make_api_call(api_params_without_required, { 'test_call' => 'value' })
      end

      it 'should call camelize_params' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret&testCall=value").
          with(webmock_default_headers).
          to_return(:status => 200, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        expect(subject).to receive(:camelize_params).and_call_original
        subject.make_api_call(api_params_without_required.merge(:camelize => true), { 'test_call' => 'value' })
      end

      it 'should call get_response' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret").
          with(webmock_default_headers).
          to_return(:status => 200, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        expect(subject).to receive(:get_response).and_call_original
        subject.make_api_call(api_params_without_required)
      end

      it 'should return hash' do
        expect(subject.make_api_call(api_params_without_required)).to be_a_kind_of(::Hash)
      end

      it 'should return Hashie::Mash' do
        expect(subject.make_api_call(api_params_without_required)).to be_a_kind_of(::Hashie::Mash)
      end

      it 'should respond to success? method in result' do
        expect(subject.make_api_call(api_params_without_required)).to respond_to(:success?)
      end

      it 'should have success? key in hash' do
        expect(subject.make_api_call(api_params_without_required)[:success?]).to be
      end

      it 'should have success? == true' do
        expect(subject.make_api_call(api_params_without_required)[:success?]).to be_truthy
      end

      it 'should have success? == false on response with status != 200' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret&testCall=value").
          with(webmock_default_headers).
          to_return(:status => 410, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        res = subject.make_api_call(api_params_without_required.merge(:camelize => true), { 'test_call' => 'value' })
        expect(res[:success?]).to be_falsey
        expect(res[:failed?]).to be_falsey
        expect(res[:not_authorized?]).to be_falsey
      end

      it 'should have not_authorized? == true' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret&testCall=value").
          with(webmock_default_headers).
          to_return(:status => 401, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        res = subject.make_api_call(api_params_without_required.merge(:camelize => true), { 'test_call' => 'value' })
        expect(res[:success?]).to be_falsey
        expect(res[:not_authorized?]).to be_truthy
        expect(res[:failed?]).to be_falsey
      end

      it 'should have failed? == true' do
        stub_request(:get, "https://rest.nexmo.com/test/url?api_key=test_api&api_secret=test_secret&testCall=value").
          with(webmock_default_headers).
          to_return(:status => 420, :body => {}.to_json, :headers => { 'Content-Type' => 'application/json' })
        res = subject.make_api_call(api_params_without_required.merge(:camelize => true), { 'test_call' => 'value' })
        expect(res[:success?]).to be_falsey
        expect(res[:not_authorized?]).to be_falsey
        expect(res[:failed?]).to be_truthy
      end

    end

  end
end
