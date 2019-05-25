module Mdex
  module API
    def chapter(id : Int32)
      Mdex::Endpoints::Chapter.get(id)
    end

    def manga(id : Int32)
      Mdex::Endpoints::Manga.get(id)
    end

    def group(id : Int32)
      Mdex::Endpoints::Group.get(id)
    end

    def genre(id : Int32)
      Mdex::Endpoints::Genre.get(id)
    end

    def search(query : String, options : Hash(String, String) = {} of String => String, fields_only : Bool = false)
      Mdex::Endpoints::Genre.get(query, options, fields_only)
    end

    def updates
      Mdex::Endpoints::Updates.get
    end

    def user(id : Int32)
      Mdex::Endpoints::User.get(id)
    end
  end
end
