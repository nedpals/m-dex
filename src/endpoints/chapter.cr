require "json"

module Mdex::Endpoints
  class Chapter < Mdex::Endpoint

    @@id = 0

    def self.get(@@id : Int32)
      use_parser = false

      super("api/chapter/#{@@id}")
    end

    def self.check_data
      case response.status_code
      when 200
        display_data
      when 404
        {
          error_code: 404,
          message: "Requested resource was not found."
        }.to_json
      end
    end

    def self.display_data
      parsed_data = JSON.parse(response.body)

      insert_ids(data)
      parse_and_insert_data(data, parsed_data)
    end

    def self.insert_ids(data)
      data["id"] = @@id
    end

    def self.parse_and_insert_data(data, json)
      data["manga_id"] = json["manga_id"].as_i
      data["page_length"] = json["page_array"].as_a.size
      data["server_url"] = json["server"].as_s === "/data/" ? "https://s4.mangadex.org/data/" : json["server"].as_s
      data["pages"] = json["page_array"].as_a.map { |x| x.as_s }
      data["long_strip"] = json["long_strip"].as_i
    end
  end
end
