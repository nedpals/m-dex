require "json"

module Mdex
  module Schema
    class Genre
      JSON.mapping({
        id: Int32,
        name: String,
        description: String?
      })
    end
  end
end
