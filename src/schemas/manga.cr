require "json"

module Mdex
  module Schema
    class Manga
      JSON.mapping({
        id: Int32,
        name: String,
        alternate_names: Array(String),
        author: String,
        artist: String,
        format: Array(Mdex::Schema::Genre)?,
        demographic: Array(Mdex::Schema::Genre)?,
        genre: Array(Mdex::Schema::Genre),
        theme: Array(Mdex::Schema::Genre)?,
        bayesian_rating: Float64,
        mean_rating: Float64,
        users_rated: Int32,
        status: String,
        description: String,
        official: Array(String)?,
        links: Array(Hash(String, String | Nil)),
        views: Int32,
        follows: Int32,
        total_chapters: Int32
      })
    end
  end
end
