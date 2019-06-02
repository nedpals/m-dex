require "json"

module Mdex::Endpoints
  class Updates < Mdex::Endpoint
    @@page_number = 1

    alias Node = Myhtml::Node | Nil

    def self.get(@@page_number : Int32 = 1)
      super("updates/#{@@page_number}")
    end

    def self.error_criteria
      @@page_number <= 0
    end

    def self.insert_ids(data)
      data["current_page"] = @@page_number
    end

    def self.display_data(html)
      parse_and_insert_data(data, html)
      insert_ids(data)

      if (@@page_number > data["total_pages"].as(Int32))
        display_error(400, "Maximum number of pages is #{data["total_pages"]}")
      else
        data
      end
    end

    def self.parse_and_insert_data(data, html)
      # Removes all empty nodes
      mangas = html.css(".table-responsive table tbody tr td").to_a
      manga_list = [] of Hash(String, FieldType)
      manga_chapters = [] of Hash(String, FieldType)
      manga = {} of String => FieldType
      chapter = {} of String => FieldType

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
          manga["link"] = node.scope.nodes(:a).to_a[0].attribute_by("href").not_nil!
          manga["id"] = parse_path(node.scope.nodes(:a).to_a[0].attribute_by("href").not_nil!)[1].to_i
        end

        if (node.attributes.empty?)
          pagination_info = parse_chapter_name_and_link(node)

          chapter["name"] = pagination_info[0]
          chapter["link"] = pagination_info[1]
          chapter["id"] = parse_path(pagination_info[1])[1].to_i
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
            manga_chapters = manga_chapters + [chapter.clone].as(Array(Hash(String, FieldType)))
            chapter_idx = chapter_idx += 1
            chapter.clear
          end
        end

        if (next_node.attributes.has_key?("rowspan"))
          if (node.attribute_by("class") == "text-right")
            manga_idx = manga_idx += 1
            chapter_idx = 0

            manga["chapters"] = manga_chapters.as(Array).map { |c| c.as(FieldType) }
            manga_list = manga_list + [manga.clone].as(Array(Hash(String, FieldType)))
            manga.clear
            manga_chapters.clear
            chapter.clear
          end
        end
      end

      data["results"] = manga_list.map { |m| m.as(FieldType) }

      pagination_info = parse_updates_pagination(html)
      data["max_results_per_page"] = pagination_info[0] || data["results"].as(Array).size
      data["total_results"] = pagination_info[1] || data["results"].as(Array).size
      data["total_pages"] = pagination_info[2] || 1
    end

    private def self.parse_updates_pagination(html)
      pagination_info_text = html.css("p.mt-3.text-center").map(&.inner_text).to_a[0]?
      pagination_info_arr = [] of Int32 | Nil

      if (pagination_info_text)
        pagination_info = pagination_info_text.clone.gsub(/\b(Showing|to|of|titles)\b/, "").split(" ").select { |x| x.size != 0 }

        pages = parse_int(pagination_info[2]) / parse_int(pagination_info[1])
        remainder = parse_int(pagination_info[2]) % parse_int(pagination_info[1])

        pagination_info_arr << parse_int(pagination_info[1])
        pagination_info_arr << parse_int(pagination_info[2].tr(",", ""))
        pagination_info_arr << (remainder != 0 ? pages+1 : pages)
      else
        pagination_info_arr << nil
        pagination_info_arr << nil
        pagination_info_arr << nil
      end

      pagination_info_arr
    end

    private def self.parse_cover_image_url(node : Node)
      image_src = node.scope.nodes(:a).to_a[0].child!.attribute_by("src")
      cover_image = "https://mangadex.org#{image_src}"

      cover_image
    end

    private def self.parse_manga_title(node : Node)
      manga_title = node.scope.nodes(:a).map(&.attribute_by("title")).to_a[0]

      manga_title.not_nil!
    end

    private def self.parse_chapter_name_and_link(node : Node)
      chap = node.scope.nodes(:a).to_a[0]

      chapter_title = chap.inner_text.not_nil!
      chapter_id = chap.attribute_by("href").not_nil!

      [chapter_title, chapter_id]
    end

    private def self.parse_chapter_language(node : Node)
      chapter_language = node.child!.attribute_by("title").not_nil!

      chapter_language
    end

    private def self.parse_chapter_translation_groups(node : Node)
      chapter_translation_groups = [] of FieldType

      node.scope.nodes(:a).each do |tg|
        translation_group = {} of String => FieldType

        translation_group["name"] = tg.inner_text
        translation_group["link"] = tg.attribute_by("href").not_nil!
        translation_group["id"] = parse_path(tg.attribute_by("href").not_nil!)[1].to_i

        chapter_translation_groups << translation_group
      end

      chapter_translation_groups
    end

    private def self.parse_chapter_uploader(node : Node)
      uploader_info = node.child!
      chapter_uploader = {} of String => FieldType

      chapter_uploader["name"] = uploader_info.inner_text
      chapter_uploader["link"] = uploader_info.attributes["href"]
      chapter_uploader["id"] = parse_path(uploader_info.attributes["href"])[1].to_i

      chapter_uploader
    end

    private def self.parse_chapter_view_counter(node : Node)
      chapter_views = parse_int(node.inner_text)

      chapter_views
    end

    private def self.parse_chapter_upload_datetime(node : Node)
      chapter_uploaded_date = node.child!.attribute_by("datetime").not_nil!

      chapter_uploaded_date
    end
  end
end
