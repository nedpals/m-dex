require "http/client"

module Mdex
  class Client
    def self.get(endpoint : String, params = {} of String => String)
      _params = HTTP::Params.encode(params)

      HTTP::Client.get("https://mangadex.org/#{endpoint}?#{params}")
    end
  end
end
