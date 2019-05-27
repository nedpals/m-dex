require "json"

module Mdex::Endpoints
  class Updates
    # Type definitions for Manga Info
    alias MangaCoverImage = String
    alias MangaTitle = String
    alias MangaLink = String
    alias MangaId = Int32
    alias ChapterName = String
    alias ChapterId = Int32
    alias ChapterLink = String
    alias ChapterLanguage = String
    alias TranslationGroup = Hash(String, String | Int32)
    alias ChapterTranslationGroups = Array(TranslationGroup)
    alias ChapterUploader = Hash(String, String | Int32)
    alias ChapterViews = Int32
    alias ChapterUploadDate = String

    alias ChapterInfo = ChapterName | ChapterId | ChapterLink | ChapterLanguage | ChapterTranslationGroups | ChapterUploader | ChapterViews | ChapterUploadDate
    alias Chapter = Hash(String, ChapterInfo)

    alias Chapters = Array(Chapter)
    alias MangaInfo = MangaCoverImage | MangaTitle | MangaLink | MangaId | Chapters
    alias Manga = Hash(String, MangaInfo)

    alias MangaList = Array(Manga)

    alias Node = Myhtml::Node | Nil

    @@updates = {} of String => MangaList | Int32 | String

    def self.get(page_number : Int32 = 1)
      response = Mdex::Client.get("updates/#{page_number}")
      html = Myhtml::Parser.new(response.body)
      error_banner = html.css(".alert.alert-warning.text-center").to_a

      if (page_number <= 0 || (error_banner.size == 1))
        {
          error_code: 404,
          message: error_banner.map(&.inner_text).to_a.join("").to_s
        }.to_json
      else
        parse_data(html)
        @@updates["current_page"] = page_number

        if (page_number > @@updates["total_pages"].as(Int32))
          {
            error_code: 400,
            message: "Maximum number of pages is #{@@updates["total_pages"]}"
          }.to_json
        else
          @@updates.to_json
        end
      end
    end

    private def self.parse_data(html)
      updates = {} of String => MangaList | Int32 | String
      # Removes all empty nodes
      mangas = html.css(".table-responsive table tbody tr td").to_a
      manga_list = [] of Manga
      manga = Hash(String, MangaInfo).new
      manga_chapters = [] of Chapter
      chapter = Hash(String, ChapterInfo).new

      manga_idx = 0
      chapter_idx = 0

      mangas.each_with_index do |node, idx|
        next_node = mangas[idx+1]? ? mangas[idx+1] : node
        prev_node = mangas[idx-1]? ? mangas[idx-1] : node

        if (["2", "3", "4", "5"].includes?(node.attribute_by("rowspan")))
          manga["cover_image"] = parse_cover_image_url(node)
        end

        if (node.attribute_by("colspan") == "6")
          manga["title"] = parse_manga_title(node)
          manga["link"] = node.scope.nodes(:a).to_a[0].attribute_by("href").as(String)
          manga["id"] = node.scope.nodes(:a).to_a[0].attribute_by("href").as(String).split("/", remove_empty: true)[1].to_i
        end

        if (node.attributes.empty?)

          pagination_info = parse_chapter_name_and_link(node)

          chapter["name"] = pagination_info[0]
          chapter["link"] = pagination_info[1]
          chapter["id"] = pagination_info[1].split("/", remove_empty: true)[1].to_i
        end

        if (node.attribute_by("class") == "text-center" && next_node.attribute_by("class") == "position-relative")
          chapter["language"] = parse_chapter_language(node)
        end

        if (node.attribute_by("class") == "position-relative" && !node.attributes.has_key?("colspan"))
          chapter["translation_groups"] = parse_chapter_translation_groups(node)
        end

        if (node.attribute_by("class") == "d-none d-lg-table-cell")
          chapter["uploader"] = parse_chapter_uploader(node)
        end

        if (node.attribute_by("class") == "d-none d-lg-table-cell text-center text-info")
          chapter["views"] = parse_chapter_view_counter(node)
        end

        if (node.attribute_by("class") == "text-right" && !node.inner_text.empty?)
          chapter["upload_date"] = parse_chapter_upload_datetime(node)
        end

        if (next_node.attributes.has_key?("rowspan") || next_node.attribute_by("class") == "text-right")
          if (node.attribute_by("class") == "text-right")
            manga_chapters = manga_chapters + [chapter.clone]
            chapter_idx = chapter_idx += 1
            chapter.clear
          end
        end

        if (next_node.attributes.has_key?("rowspan"))
          if (node.attribute_by("class") == "text-right")
            manga_idx = manga_idx += 1
            chapter_idx = 0

            manga["chapters"] = manga_chapters.as(Chapters)
            manga_list = manga_list + [manga.clone]
            manga.clear
            manga_chapters.clear
            chapter.clear
          end
        end
      end

      pagination_info = parse_updates_pagination(html)

      updates["max_results_per_page"] = pagination_info[0]
      updates["total_results"] = pagination_info[1]
      updates["total_pages"] = pagination_info[2]

      updates["results"] = manga_list

      @@updates = updates
    end

    private def self.parse_updates_pagination(html)
      pagination_info_text = html.css("p.mt-3.text-center").map(&.inner_text).to_a[0]
      pagination_info = pagination_info_text.clone.gsub(/\b(Showing|to|of|chapters)\b/, "").split(" ").select { |x| x.size != 0 }
      pagination_info_arr = [] of Int32

      pages = pagination_info[2].tr(",", "").to_i.to_i / pagination_info[1].tr(",", "").to_i.to_i
      remainder = pagination_info[2].tr(",", "").to_i.to_i % pagination_info[1].tr(",", "").to_i.to_i

      pagination_info_arr << pagination_info[1].tr(",", "").to_i
      pagination_info_arr << pagination_info[2].tr(",", "").to_i
      pagination_info_arr << (remainder != 0 ? pages+1 : pages)

      pagination_info_arr
    end

    private def self.parse_cover_image_url(node : Node) : MangaCoverImage
      image_src = node.scope.nodes(:a).to_a[0].child!.attribute_by("src")
      cover_image = "https://mangadex.org#{image_src}"

      cover_image.as(MangaCoverImage)
    end

    private def self.parse_manga_title(node : Node) : MangaTitle
      manga_title = node.scope.nodes(:a).map(&.attribute_by("title")).to_a[0]

      manga_title.as(MangaTitle)
    end

    private def self.parse_chapter_name_and_link(node : Node) : Array(ChapterName | ChapterLink)
      chap = node.scope.nodes(:a).to_a[0]

      chapter_title = chap.inner_text
      chapter_id = chap.attribute_by("href")

      [chapter_title.as(ChapterName), chapter_id.as(ChapterLink)]
    end

    private def self.parse_chapter_language(node : Node) : ChapterLanguage
      chapter_language = node.child!.attribute_by("title")

      chapter_language.as(ChapterLanguage)
    end

    private def self.parse_chapter_translation_groups(node : Node) : ChapterTranslationGroups
      chapter_translation_groups = [] of TranslationGroup

      node.scope.nodes(:a).each do |tg|
        translation_group = {} of String => String | Int32

        translation_group["name"] = tg.inner_text
        translation_group["link"] = tg.attribute_by("href").not_nil!
        translation_group["id"] = tg.attribute_by("href").not_nil!.split("/", remove_empty: true)[1].to_i

        chapter_translation_groups << translation_group
      end

      chapter_translation_groups.as(ChapterTranslationGroups)
    end

    private def self.parse_chapter_uploader(node : Node) : ChapterUploader
      uploader_info = node.child!
      chapter_uploader = {} of String => String | Int32

      chapter_uploader["name"] = uploader_info.inner_text
      chapter_uploader["link"] = uploader_info.attributes["href"]
      chapter_uploader["id"] = uploader_info.attributes["href"].split("/", remove_empty: true)[1].to_i

      chapter_uploader.as(ChapterUploader)
    end

    private def self.parse_chapter_view_counter(node : Node) : ChapterViews
      chapter_views = node.inner_text.tr(",", "").to_i

      chapter_views.as(ChapterViews)
    end

    private def self.parse_chapter_upload_datetime(node : Node) : ChapterUploadDate
      chapter_uploaded_date = node.child!.attribute_by("datetime")

      chapter_uploaded_date.as(ChapterUploadDate)
    end
  end
end
