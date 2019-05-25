require "json"

module Mdex::Endpoints
  class Chapter
    alias ChapterImagesInfo = String | Int32 | JSON::Any | Array(JSON::Any)
    alias ChapterImages = Hash(String, ChapterImagesInfo)

    def self.get(id : Int32)
      response = Mdex::Client.get("api/chapter/#{id}")
      data = JSON.parse(response.body)
      images_hash = {} of String => ChapterImagesInfo

      images_hash["id"] = id
      images_hash["manga_id"] = data["manga_id"]
      images_hash["page_length"] = data["page_array"].as_a.size
      images_hash["server_url"] = data["server"].as_s === "/data/" ? "https://s4.mangadex.org/data/" : data["server"].as_s
      images_hash["pages"] = data["page_array"].as_a
      images_hash["long_strip"] = data["long_strip"].as_i

      images_hash.as(ChapterImages).to_json
    end
  end
end
