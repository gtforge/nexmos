require 'faraday_middleware/response/mashify'

module FaradayMiddleware
  # Public: Converts parsed response bodies to a Hashie::Trash if they were of
  # Hash or Array type.
  class MashRashify < Mashify
    dependency do
      require 'hashie/mash/rash'
      self.mash_class = ::Hashie::Mash::Rash
    end
  end
end

if Faraday::Middleware.respond_to? :register_middleware
  Faraday::Response.register_middleware mashrashify: FaradayMiddleware::MashRashify
end

# deprecated alias
Faraday::Response::MashRashify = FaradayMiddleware::MashRashify
