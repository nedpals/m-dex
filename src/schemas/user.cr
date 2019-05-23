require "json"

module Mdex
  module Schema
    class User
      JSON.mapping({
        id: Int32,
        username: String,
        level: String,
        created: {type: Time, converter: Time::Format.new("%F")},
        translation_groups: Array(Mdex::Schema::TranslationGroup),
        views: Int32,
        mangas_uploaded: Int32,
        biography: String
      })
    end
  end
end
