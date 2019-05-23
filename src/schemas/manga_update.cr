require "json"

module Mdex
  module Schema
    class MangaUpdate
      JSON.mapping({
        id: Int32,
        name: String,
        latest_chapter: String,
        translation_groups: Array(Mdex::Schema::TranslationGroup),
        uploader: Mdex::Schema::User,
        views: Int32,
        last_updated: {type: Time, converter: Time::Format.new("%F %X UTC")},
      })
    end
  end
end
