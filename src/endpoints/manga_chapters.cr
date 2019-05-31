require "json"

module Mdex::Endpoints
  class MangaChapters
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

    @@chapters = {} of String => Chapters | ChapterResultPage

    def self.get(id : Int32, page_number : Int32 = 1)
      response = Mdex::Client.get("title/#{id}/chapters/#{page_number}")
      html = Myhtml::Parser.new(response.body)
      error_banner = html.css(".alert.alert-danger.text-center").to_a

      error_json = { error_code: 404,  message: error_banner.map(&.inner_text).to_a.join("").to_s }.to_json

      if ((page_number <= 0 || id <= 0) || (error_banner.size == 1))
        error_json
      else
        @@chapters["current_page"] = page_number
        @@chapters["manga_id"] = id
        parse_data(html)

        if (page_number > @@chapters["chapter_pages_per_result"].as(Int32))
          {
            error_code: 400,
            message: "Maximum number of pages is #{@@chapters["chapter_pages_per_result"]}"
          }.to_json
        else
          @@chapters.to_json
        end
      end
    end

    private def self.parse_data(html)
      @@chapters["chapters"] = parse_chapters(html)

      if (html.css("p.mt-3.text-center").to_a.size != 0)
        parse_manga_chapters_pagination(html)
      else
        @@chapters["chapter_list_max_results"] = @@chapters["chapters"].as(Chapters).size
        @@chapters["total_chapters"] = @@chapters["chapters"].as(Chapters).size.as(ChapterResultPage)
        @@chapters["chapter_pages_per_result"] = 1.as(ChapterResultPage)
      end
    end

    private def self.parse_chapters(html)
      manga_chapters = [] of Chapter
      html.css(".chapter-container .row.no-gutters [data-id]").each_with_index do |node, idx|
        root_nodes = node.scope.nodes(:div)
        chapter_info = {} of String => ChapterInfo

        puts root_nodes.to_a

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

    private def self.parse_manga_chapters_pagination(html)
      chap_info_text = html.css("p.mt-3.text-center").map(&.inner_text).to_a[0]
      chapter_info = chap_info_text.clone.gsub(/\b(Showing|to|of|chapters)\b/, "").split(" ").select { |x| x.size != 0 }

      pages = chapter_info[2].tr(",", "").to_i / chapter_info[1].tr(",", "").to_i
      remainder = chapter_info[2].tr(",", "").to_i % chapter_info[1].tr(",", "").to_i

      @@chapters["chapter_list_max_results"] = chapter_info[1].tr(",", "").to_i.as(ChapterResultPage)
      @@chapters["total_chapters"] = chapter_info[2].tr(",", "").to_i.as(ChapterResultPage)
      @@chapters["chapter_pages_per_result"] = (remainder != 0 ? pages+1 : pages).as(ChapterResultPage)
    end
  end
end
