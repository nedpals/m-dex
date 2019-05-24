require "http/client"

module Mdex
  class Client
    include Mdex::API

    @@base_url = "https://mangadex.org/"

    def initialize; end;

    def self.get(endpoint : String, params = {} of String => String)
      _params = HTTP::Params.encode(params)

      HTTP::Client.get("#{@@base_url}#{endpoint}?#{params}")
    end

    def self.base_url
      @@base_url
    end
  end
end
