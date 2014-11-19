require 'spec_helper'
describe ::Nexmos::Account do
  let(:webmock_default_headers) do
    {
        :headers => {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => ::Nexmos.user_agent
        }
    }
  end

  let(:finland_prices) do
    {
        "mt" => "0.02500000",
        "country" => "FI",
        "prefix" => "358",
        "networks" =>
            [{"code" => "24491",
              "network" => "sonera, TeleFinland",
              "ranges" => ["35840", "35842", "358450"],
              "mtPrice" => "0.04500000"},
             {"code" => "24414",
              "network" => "GSM Aland",
              "ranges" => ["3584570", "3584573", "3584575"],
              "mtPrice" => "0.00850000"},
             {"code" => "24421",
              "network" => "SAUNALAHTI, EUnet Finland",
              "ranges" => ["358451", "358452", "358453", "358456", "358458"],
              "mtPrice" => "0.05000000"},
             {"code" => "24412",
              "network" => "dna",
              "ranges" =>
                  ["35841",
                   "35844",
                   "3584574",
                   "3584576",
                   "3584577",
                   "3584578",
                   "3584579",
                   "3584944"],
              "mtPrice" => "0.00850000"},
             {"code" => "24405",
              "network" => "elisa",
              "ranges" => ["35846", "35850"],
              "mtPrice" => "0.05000000"}],
        "name" => "Finland"
    }.to_json
  end

  let(:prefix_prices) do
    {"count" => 1,
     "prices" =>
       [{"mt" => "0.02500000",
         "country" => "FI",
         "prefix" => "358",
         "networks" =>
           [{"code" => "24491",
             "network" => "sonera, TeleFinland",
             "ranges" => nil,
             "mt_price" => "0.04500000"},
            {"code" => "24414",
             "network" => "GSM Aland",
             "ranges" => nil,
             "mtPrice" => "0.00850000"},
            {"code" => "24400",
             "network" => "Unknown Finland",
             "ranges" => nil,
             "mtPrice" => "0.02500000"},
            {"code" => "24421",
             "network" => "SAUNALAHTI, EUnet Finland",
             "ranges" => nil,
             "mtPrice" => "0.05000000"},
            {"code" => "24412",
             "network" => "dna",
             "ranges" => nil,
             "mtPrice" => "0.00850000"},
            {"code" => "24405",
             "network" => "elisa",
             "ranges" => nil,
             "mtPrice" => "0.05000000"}],
         "name" => "Finland"}],
     }.to_json
  end

  before(:each) do
    ::Nexmos.reset!
    ::Nexmos.setup do |c|
      c.api_key = 'default_key'
      c.api_secret = 'default_secret'
    end
  end

  subject { ::Nexmos::Account.new }

  context '#get_balance' do

    it 'should return value' do
      request = stub_request(:get, "https://rest.nexmo.com/account/get-balance?api_key=default_key&api_secret=default_secret").
          with(webmock_default_headers).to_return(:status => 200, :body => {"value" => 4.107}.to_json, headers: {'Content-Type' => 'application/json'})
      res = subject.get_balance
      expect(res).to be_kind_of(::Hash)
      expect(res.value).to eq(4.107)
      expect(request).to have_been_made.once
    end
  end

  context '#get_pricing' do
    it 'should return error on missed param' do
      expect { subject.get_pricing }.to raise_error('country params required')
    end

    it 'should be success' do
      request = stub_request(:get, "https://rest.nexmo.com/account/get-pricing/outbound?api_key=default_key&api_secret=default_secret&country=FI").
          with(webmock_default_headers).to_return(:status => 200, :body => finland_prices, :headers => {'Content-Type' => 'application/json'})
      res = subject.get_pricing(:country => 'FI')
      expect(res).to be_kind_of(::Hash)
      expect(res.success?).to be_truthy
      expect(res.country).to eq('FI')
      expect(res.keys.sort).to eq(%w(country name prefix mt networks success?).sort)
      expect(res.networks).to be_kind_of(::Array)
      expect(res.networks[0].keys.sort).to eq(%w(code network mt_price ranges).sort)
      expect(request).to have_been_made.once
    end
  end

  context '#get_prefix_pricing' do
    it 'should return error on missed param' do
      expect { subject.get_prefix_pricing }.to raise_error('prefix params required')
    end

    it 'should be success' do
      request = stub_request(:get, "https://rest.nexmo.com/account/get-prefix-pricing/outbound?api_key=default_key&api_secret=default_secret&prefix=358").
          with(webmock_default_headers).to_return(:status => 200, :body => prefix_prices, :headers => {'Content-Type' => 'application/json'})
      res = subject.get_prefix_pricing(:prefix => '358')
      expect(res).to be_kind_of(::Hash)
      expect(res.success?).to be_truthy
      expect(res.keys.sort).to eq(%w(count prices success?).sort)
      expect(res.prices).to be_kind_of(::Array)
      expect(res.prices[0].keys.sort).to eq(%w(country name prefix mt networks).sort)
      expect(res.prices[0].networks).to be_kind_of(::Array)
      expect(res.prices[0].networks[0].keys.sort).to eq(%w(code network mt_price ranges).sort)
      expect(request).to have_been_made.once
    end
  end

  context '#get_numbers' do
    it 'should return only count on empty numbers' do
      request = stub_request(:get, "https://rest.nexmo.com/account/numbers?api_key=default_key&api_secret=default_secret").
          with(webmock_default_headers).to_return(:status => 200, :body => {:count => 0}.to_json, :headers => {'Content-Type' => 'application/json'})
      res = subject.get_numbers
      expect(res).to be_kind_of(::Hash)
      expect(res.success?).to be_truthy
      expect(res['count']).to eq(0)
      expect(request).to have_been_made.once
    end

    it 'should return numbers array' do
      request = stub_request(:get, "https://rest.nexmo.com/account/numbers?api_key=default_key&api_secret=default_secret").
          with(webmock_default_headers).to_return(:status => 200,
                                                  :body => {
                                                    "count" => 1,
                                                    "numbers" => [
                                                      {"country" => "ES","msisdn" => "34911067000","type" => "landline"}
                                                    ]
                                                  }.to_json, :headers => {'Content-Type' => 'application/json'})
      res = subject.get_numbers
      expect(res).to be_kind_of(::Hash)
      expect(res.success?).to be_truthy
      expect(res['count']).to eq(1)
      expect(res['numbers']).to be_kind_of(::Array)
      expect(res['numbers'].first).to be_kind_of(::Hash)
      expect(res['numbers'].first).to eq({"country" => "ES","msisdn" => "34911067000","type" => "landline"})
      expect(request).to have_been_made.once
    end
  end

  context '#top_up' do
    it 'should return error on missed param' do
      expect { subject.top_up }.to raise_error('trx params required')
    end

    it 'should success top up' do
      request = stub_request(:get, "https://rest.nexmo.com/account/top-up?api_key=default_key&api_secret=default_secret&trx=test_trx").
          with(webmock_default_headers).to_return(:status => 200, :body => '', :headers => {'Content-Type' => 'application/json'})
      res = subject.top_up :trx => 'test_trx'
      expect(res).to be_kind_of(::Hash)
      expect(res.success?).to be_truthy
      expect(request).to have_been_made.once
    end

  end

end
