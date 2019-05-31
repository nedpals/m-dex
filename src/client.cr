require "halite"

module Mdex
  class Client
    include Mdex::API
    @@client = Halite::Client.new
    @@base_url = String.new

    def initialize(@@base_url : String = "https://mangadex.org/"); end

    def self.get(endpoint : String, params = {} of String => String)
      _params = HTTP::Params.encode(params)

      @@client.get("#{@@base_url}#{endpoint}", params: params)
    end

    def self.base_url
      @@base_url
    end
  end
end
