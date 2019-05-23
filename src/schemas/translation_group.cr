require "json"

module Mdex
  module Schema
    class TranslationGroup
      JSON.mapping({
        id: Int32,
        name: String,
        description: String?,
        banner: String?,
        alternate_names: Array(String)?,
        links: Array(String)?,
        members: Array(String)?
      })
    end
  end
end
