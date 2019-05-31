module Mdex::Endpoints
  class Test < Mdex::Endpoint
    def self.get(id : Int32)
      super("https://mangadex.org/#{id}")
    end

    # def self.parse_data
    #   puts @url
    # end
  end
end
