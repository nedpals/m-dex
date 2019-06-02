module Mdex
  module API
    def chapter(id : Int32) : String
      Mdex::Endpoints::Chapter.get(id)
    end

    def manga(id : Int32, title_slug : String = "", page_number : Int32 = 1, chapters_only : Bool = false) : String
      if (chapters_only && page_number >= 1)
        Mdex::Endpoints::MangaChapters.get(id, title_slug, page_number)
      else
        Mdex::Endpoints::Manga.get(id, title_slug)
      end
    end

    def group(id : Int32) : String
      Mdex::Endpoints::Group.get(id)
    end

    def genre(id : Int32) : String
      Mdex::Endpoints::Genre.get(id)
    end

    def search(query : String, options : Hash(String, String) = {} of String => String, fields_only : Bool = false) : String
      Mdex::Endpoints::Genre.get(query, options, fields_only)
    end

    def updates(page_number : Int32 = 1) : String
      Mdex::Endpoints::Updates.get(page_number)
    end

    def user(id : Int32) : String
      Mdex::Endpoints::User.get(id)
    end
  end
end
