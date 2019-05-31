require "json"

module Mdex::Endpoints
  class Chapter
    alias ChapterImagesInfo = String | Int32 | JSON::Any | Array(JSON::Any)
    alias ChapterImages = Hash(String, ChapterImagesInfo)

    @@images_hash = {} of String => ChapterImagesInfo

    def self.get(id : Int32)
      response = Mdex::Client.get("api/chapter/#{id}")

      case response.status_code
      when 200
        @@images_hash["id"] = id

        data = JSON.parse(response.body)
        parse_data(data)
      when 404
        {
          error_code: 404,
          message: "Requested resource was not found."
        }.to_json
      end
    end

    private def self.parse_data(data : JSON::Any)
      @@images_hash["manga_id"] = data["manga_id"]
      @@images_hash["image_hash"] = data["hash"]
      @@images_hash["page_length"] = data["page_array"].as_a.size
      @@images_hash["server_url"] = data["server"].as_s === "/data/" ? "https://mangadex.org/data/" : data["server"].as_s
      @@images_hash["pages"] = data["page_array"].as_a
      @@images_hash["long_strip"] = data["long_strip"].as_i

      @@images_hash.as(ChapterImages).to_json
    end
  end
end
