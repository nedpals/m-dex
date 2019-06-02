require "halite"

module Mdex
  class Client
    include Mdex::API

    VERSION = "0.2"
    USER_AGENT = "M-dex #{VERSION} (Crystal #{Crystal::VERSION})"

    @@client = Halite::Client.new
    @@base_url = String.new

    def initialize(@@base_url : String = "https://mangadex.org/"); end

    def self.get(endpoint : String, params = {} of String => String)
      _params = HTTP::Params.encode(params)

      @@client.user_agent(USER_AGENT).get("#{@@base_url}#{endpoint}", params: params)
    end

    def self.base_url
      @@base_url
    end
  end
end
