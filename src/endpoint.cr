require "http/client/response"

module Mdex
  class Endpoint
    alias DataField = String | Int32
    alias Fields = DataField | Hash(String, DataField) | Array(DataField)

    @@path = "/"
    @@data = initialize_data
    @@response = HTTP::Client::Response.new(200, "")
    @@use_parser = true
    @@html = Myhtml::Parser.new(@@response.body)

    def self.get(@@path : String)
      response = Mdex::Client.get(@@path)

      check_data
    end

    def self.check_data
      html = @@use_parser ? @@html : ""
      error_banner = html.css(".alert.alert-danger.text-center").to_a

      if (id <= 0 || (error_banner.size == 1))
        display_error(404, error_banner.map(&.inner_text).to_a.join("").to_s).to_json
      else
        display_data(html).to_json
      end
    end

    def self.display_data(html)
      insert_ids(@@data)
      parse_and_insert_data(@@data, html)
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
      Hash(String, Fields).new
    end

    def self.response
      @@response
    end

    def self.response=(content : HTTP::Client::Response)
      @@response = content
    end

    def self.use_parser=(value : Bool = true)
      @@use_parser = value
    end

    def self.display_error(error_code : Int32 = 404, error_message : String = "")
      {
        error_code => error_code,
        message => error_message
      }
    end
  end
end
