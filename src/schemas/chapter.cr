require "json"

module Mdex
  module Schema
    class Chapter
      JSON.mapping({
        id: Int32,
        name: String,
        translation_groups: Array(Mdex::Schema::TranslationGroup),
        uploader: Mdex::Schema::User,
        views: Int32,
        uploaded: {type: Time, converter: Time::Format.new("%F %X UTC")}
      })
    end
  end
end
