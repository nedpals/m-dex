require "uri"
require "json"

module Mdex::Endpoints
  class Manga
    # Manga Info Type Definitions
    alias MangaId = Int32
    alias AltNames = Array(String)
    alias Artist = String
    alias Author = String
    alias CoverPhoto = String
    alias Demographic = String
    alias Demographics = Array(Demographic)
    alias Description = String
    alias Format = String
    alias Formats = Array(Format)
    alias Genre = String | Int32 | Nil
    alias Genres = Array(Hash(String, Genre))
    alias Link = String | Nil
    alias Links = Array(Hash(String, Link))
    alias Rating = Int32 | Float32 | Float64 | String
    alias RatingHash = Hash(String, Rating)
    alias Ratings = Array(Rating)
    alias Stat = Int32
    alias Stats = Array(Stat)
    alias Status = String
    alias Theme = String
    alias Themes = Array(Theme)

    # Chapter Type definitions
    alias ChapterResultPage = Int32
    alias ChapterId = Int32
    alias ChapterName = String
    alias ChapterLink = String
    alias ChapterUploadDate = String
    alias ChapterLanguage = String
    alias TranslationGroup = Hash(String, String | Int32)
    alias ChapterTranslationGroups = Array(TranslationGroup)
    alias ChapterUploader = Hash(String, String | Int32)
    alias ChapterViews = String | Int32
    alias ChapterImagesInfo = String | Int32 | JSON::Any | Array(JSON::Any)
    alias ChapterImages = Hash(String, ChapterImagesInfo)
    alias ChapterInfo = ChapterResultPage | ChapterImages | ChapterId | ChapterName | ChapterLink | ChapterUploadDate | ChapterLanguage | ChapterTranslationGroups | ChapterUploader | ChapterViews
    alias Chapter = Hash(String, ChapterInfo)
    alias Chapters = Array(Chapter)

    alias MangaInfo = MangaId | AltNames | Artist | Author | CoverPhoto | Chapters | Demographics | Description | Formats | Genres | Links | Ratings | Rating | Stats | Status | Themes | Chapter | Hash(String, MangaInfo) | Array(MangaInfo)
    alias Node = Myhtml::Node | Nil

    @@manga = Hash(String, MangaInfo).new

    def self.get(id : MangaId)
      manga = Hash(String, MangaInfo).new
      response = Mdex::Client.get("title/#{id}")
      html = Myhtml::Parser.new(response.body)
      error_banner = html.css(".alert.alert-danger.text-center").to_a

      if (id <= 0 || (error_banner.size == 1))
        {
          error_code: 404,
          message: error_banner.map(&.inner_text).to_a.join("").to_s
        }.to_json
      else
        @@manga["id"] = id
        parse_data(html)
      end
    end

    def self.parse_data(html)
      # Get manga cover image
      cover_photo_path = html.css(".card-body .row .col-xl-3 img").map(&.attribute_by("src")).to_a[0]
      @@manga["cover_photo"] = "#{Mdex::Client.base_url}#{cover_photo_path.not_nil!.lchop}".as(CoverPhoto)

      # Get manga name
      @@manga["name"] = html.css(".card .card-header span:nth-child(2)").map(&.inner_text).to_a[0]


      # Get manga info
      info_nodes_names = [] of String

      html.css(".card-body .row .col-xl-9 .row .col-xl-2").each do |node|
        node_name = node.inner_text.strip(":").downcase
        info_nodes_names << node_name
      end

      html.css(".card-body .row .col-xl-9 .row .col-xl-10").each_with_index do |node, idx|
        if idx < info_nodes_names.size
          case info_nodes_names[idx]
          when "alt name(s)"
            @@manga["alternate_names"] = parse_alt_names(node)
          when "author"
            @@manga["author"] = parse_author(node)
          when "artist"
            @@manga["artist"] = parse_artist(node)
          when "demographic"
            @@manga["demographics"] = parse_demographic(node)
          when "format"
            @@manga["format"] = parse_format(node)
          when "genre"
            @@manga["genre"] = parse_genre(node)
          when "official"
            @@manga["official"] = parse_official_links(node)
          when "rating"
            ratings_arr = parse_ratings(node)

            @@manga["bayesian_rating"] = ratings_arr[0]
            @@manga["mean_rating"] = ratings_arr[1]
            @@manga["users_rated"] = ratings_arr[2]
          when "retail"
            @@manga["retail"] = parse_retail_links(node)
          when "pub. status"
            @@manga["status"] = parse_status(node)
          when "stats"
            stats_arr = parse_stats(node)

            @@manga["views"] = stats_arr[0]
            @@manga["follows"] = stats_arr[1]
            @@manga["total_chapters"] = stats_arr[2]
          when "theme"
            @@manga["theme"] = parse_theme(node)
          when "description"
            @@manga["description"] = parse_description(node)
          when "information"
            @@manga["links"] = parse_links(node)
          end
        end
      end

      if (html.css("p.mt-3.text-center").to_a.size != 0)
        parse_manga_chapters_pagination(html)
      end

      @@manga["chapters"] = parse_manga_chapters(html)
      @@manga.to_json
    end

    private def self.parse_manga_chapters_pagination(html)
      chap_info_text = html.css("p.mt-3.text-center").map(&.inner_text).to_a[0]
      chapter_info = chap_info_text.clone.gsub(/\b(Showing|to|of|chapters)\b/, "").split(" ").select { |x| x.size != 0 }

      pages = chapter_info[2].tr(",", "").to_i.to_i / chapter_info[1].tr(",", "").to_i.to_i
      remainder = chapter_info[2].tr(",", "").to_i.to_i % chapter_info[1].tr(",", "").to_i.to_i

      @@manga["chapter_list_max_results"] = chapter_info[1].tr(",", "").to_i.to_i.as(ChapterResultPage)
      @@manga["total_chapters"] = chapter_info[2].tr(",", "").to_i.to_i.as(ChapterResultPage)
      @@manga["chapter_pages_per_result"] = (remainder != 0 ? pages+1 : pages).as(ChapterResultPage)
    end

    private def self.parse_manga_chapters(html) : Chapters
      manga_chapters = [] of Chapter
      html.css(".chapter-container .row.no-gutters [data-id]").each_with_index do |node, idx|
        root_nodes = node.scope.nodes(:div)
        chapter_info = {} of String => ChapterInfo

        chapter_info["id"] = node.attributes["data-id"].to_i32.as(ChapterId)
        root_nodes.each_with_index do |n, n_idx|
          field = n.scope
          case n_idx
          when 1
            link = field.nodes(:a).first

            chapter_info["name"] = link.inner_text.as(ChapterName)
            chapter_info["url"] = link.attribute_by("href").as(ChapterLink)
          # when 3
          #   comments = field.nodes(:a).first

          #   chapter_info["comments_url"] = comments.attributes["href"] || "/chapter/#{chapter_info["id"]}/comments"
          #   chapter_info["comments"] = comments.scope.nodes(:span).first.inner_text.strip || "0"
          when 4
            chapter_info["uploaded"] = n.attribute_by("title").as(ChapterUploadDate)
          when 6
            chapter_info["language"] = field.nodes(:span).first.attribute_by("title").as(ChapterLanguage)
          when 7
            group_arr = [] of TranslationGroup

            field.nodes(:a).each do |t|
              group_arr << {
                "name" => t.inner_text,
                "url" => t.attributes["href"],
                "id" => t.attributes["href"].split("/", remove_empty: true)[1].to_i
              }
            end

            chapter_info["translation_groups"] = group_arr.as(ChapterTranslationGroups)
          when 8
            uploader = field.nodes(:a).first
            chapter_info["uploader"] = {
              "name" => uploader.inner_text,
              "url" => uploader.attributes["href"],
              "id" => uploader.attributes["href"].split("/", remove_empty: true)[1].to_i
            }.as(ChapterUploader)
          when 9
            views = field.nodes(:span).first
            chapter_info["views"] = views.inner_text.tr(",", "").to_i.as(ChapterViews)
          end
        end

        manga_chapters.push(chapter_info.as(Chapter))

      end
      manga_chapters.as(Chapters)
    end

    private def self.parse_alt_names(node : Node) : AltNames
      alt_names_ul = node.scope.nodes(:ul).first
      alt_names = alt_names_ul.scope.nodes(:li).map(&.inner_text).to_a

      alt_names.map(&.strip).as(AltNames)
    end

    private def self.parse_author(node : Node) : Author
      node.scope.nodes(:a).first.inner_text.strip.as(Artist)
    end

    private def self.parse_artist(node : Node) : Artist
      node.scope.nodes(:a).first.inner_text.strip.as(Artist)
    end

    private def self.parse_demographic(node : Node) : Demographics
      node.scope.nodes(:span).map(&.inner_text).to_a.as(Demographics)
    end

    private def self.parse_theme(node : Node) : Themes
      node.scope.nodes(:a).map(&.inner_text).to_a.as(Themes)
    end

    private def self.parse_format(node : Node) : Formats
      node.scope.nodes(:a).map(&.inner_text).to_a.as(Formats)
    end

    private def self.parse_genre(node : Node) : Genres
      genres_arr = [] of Hash(String, Genre)
      node.scope.nodes(:a).each do |n|
        genre_href = n.attribute_by("href").to_s

        genre = {} of String => Genre
        genre["name"] = n.inner_text
        genre["id"] = genre_href.split("/", remove_empty: true)[1].to_i
        genres_arr << genre
      end

      genres_arr.as(Genres)
    end

    private def self.parse_links(node : Node) : Links
      links_arr = [] of Hash(String, String | Nil)
      node.scope.nodes(:ul).first.scope.nodes(:li).each do |link_node|
        link_node.scope.nodes(:a).each do |n|
          link_href = n.attribute_by("href")
          link_name = n.inner_text
          link = {} of String => String | Nil
          link[link_name] = link_href

          links_arr << link
        end
      end

      links_arr.as(Links)
    end

    private def self.parse_retail_links(node : Node) : Links
      self.parse_links(node)
    end

    private def self.parse_official_links(node : Node) : Links
      self.parse_links(node)
    end

    private def self.parse_ratings(node : Node) : Ratings
      ratings_arr = [] of Rating

      node.scope.nodes(:ul).first.scope.nodes(:li).each_with_index do |rating, rating_idx|
        if (rating_idx != 2)
          ratings_arr << rating.inner_text.strip.as(Rating)
        else
          ratings_arr << rating.inner_text.to_i.as(Rating)
        end
      end

      ratings_arr.as(Ratings)
    end

    private def self.parse_status(node : Node) : Status
      node.inner_text
    end

    private def self.parse_stats(node : Node) : Stats
      stats_arr = [] of Stat

      node.scope.nodes(:ul).first.scope.nodes(:li).each do |stat_int|
        stats_arr << stat_int.inner_text.tr(",", "").to_i.as(Stat)
      end

      stats_arr.as(Stats)
    end

    private def self.parse_description(node : Node) : Description
      node.inner_text
    end
  end
end
