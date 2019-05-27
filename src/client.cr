require "halite"

module Mdex
  class Client
    include Mdex::API

    @@base_url = "https://mangadex.org/"
    @@client = Halite::Client.new

    def initialize; end;

    def self.get(endpoint : String, params = {} of String => String)
      _params = HTTP::Params.encode(params)

      @@client.get("#{@@base_url}#{endpoint}", params: params)
    end

    def self.base_url
      @@base_url
    end
  end
end
