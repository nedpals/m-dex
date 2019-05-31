module Mdex
  class Endpoint
    alias DataFields = Int32 | Float64 | String | Hash(String, DataFields) | Array(String, DataFields)

    @@path = String.new
    @@data = {} of String => DataFields

    def self.get(@@path : String)
      @@path
    end

    def self.detect_data(html)
      error_banner = html.css(".alert.alert-danger.text-center").to_a

      if (id <= 0 || (error_banner.size == 1))
        {
          error_code: 404,
          message: error_banner.map(&.inner_text).to_a.join("").to_s
        }.to_json
      else
        @@manga["id"] = id
        parse_data(html)
      end
    end
  end
end
