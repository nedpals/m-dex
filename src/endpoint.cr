require "halite/response"
require "uri"
require "./helpers"

module Mdex
  class Endpoint
    alias FieldType = String | Int32 | Float64 | Bool | Hash(String, FieldType) | Array(FieldType)

    @@path = "/"
    @@data = Hash(String, FieldType).new || initialize_data
    @@response = Halite::Response.new(uri: URI.parse("#{Mdex::Client.base_url}#{@@path}"), status_code: 200, body: "")
    @@use_parser = true
    @@html = Myhtml::Parser.new("<html><body>test</body></html>")

    def self.get(@@path : String)
      @@response = Mdex::Client.get(@@path)
      @@html = Myhtml::Parser.new(@@response.body)

      check_data.to_json
    end

    def self.check_data
      html = @@html
      error_banner = html.css(".alert.alert-danger.text-center").to_a

      if (error_criteria || (error_banner.size == 1))
        display_error(404, error_banner.map(&.inner_text).to_a.join("").to_s)
      else
        display_data(html)
      end
    end

    def self.error_criteria
      !response.body.not_nil!
    end

    def self.display_data(html)
      insert_ids(@@data)
      parse_and_insert_data(@@data, html)

      @@data
    end

    # def self.parse_and_insert_ids(id)
    #   @@data["id"] = id
    # end

    def self.data
      @@data
    end

    def self.html
      @@html
    end

    def self.initialize_data
      Hash(String, FieldType).new
    end

    def self.response
      @@response
    end

    def self.use_parser=(value : Bool = true)
      @@use_parser = value
    end

    def self.display_error(error_code : Int32 = 404, error_message : String = "")
      {
        "error_code" => error_code,
        "message" => error_message
      }
    end

    def self.parse_int(str : String, remove_whitespace : String | Bool = false) : Int32
      MdexHelpers.parse_int(str, remove_whitespace)
    end

    def self.parse_float(str : String, remove_whitespace : String | Bool = false) : Float64
      MdexHelpers.parse_float(str, remove_whitespace)
    end

    def self.parse_path(str : String)
      MdexHelpers.parse_path(str)
    end
  end
end
