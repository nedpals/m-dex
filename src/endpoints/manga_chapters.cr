require "json"

module Mdex::Endpoints
  class MangaChapters < Mdex::Endpoint
    @@id = 0
    @@title_slug = ""
    @@page_number = 1

    def self.get(@@id : Int32, @@title_slug : String, @@page_number : Int32 = 1)
      super("title/#{@@id}/#{@@title_slug}/#{@@page_number}")
    end

    def self.error_criteria
      @@page_number <= 0 || @@id <= 0
    end

    def self.insert_ids(data)
      data["current_page"] = @@page_number
      data["id"] = @@id
    end

    def self.display_data(html)
      insert_ids(data)
      parse_and_insert_data(data, html)

      if (@@page_number > data["chapter_pages_per_result"].as(Int32))
        display_error(400, "Maximum number of pages is #{data["chapter_pages_per_result"]}")
      else
        data
      end
    end

    def self.parse_and_insert_data(data, html)
      data["chapters"] = parse_chapters(html)

      if (html.css("p.mt-3.text-center").to_a.size != 0)
        parse_manga_chapters_pagination(html)
      else
        data["chapter_list_max_results"] = data["chapters"].as(Array).size.as(Int32)
        data["total_chapters"] = data["chapters"].as(Array).size.as(Int32)
        data["chapter_pages_per_result"] = 1
      end
    end

    def self.parse_chapters(html)
      manga_chapters = [] of Hash(String, FieldType)
      html.css(".chapter-container .row.no-gutters [data-id]").each_with_index do |node, idx|
        root_nodes = node.scope.nodes(:div)
        chapter_info = {} of String => FieldType

        chapter_info["id"] = node.attributes["data-id"].to_i32
        root_nodes.each_with_index do |n, n_idx|
          field = n.scope
          case n_idx
          when 1
            link = field.nodes(:a).first

            chapter_info["name"] = link.inner_text
            chapter_info["url"] = link.attribute_by("href").not_nil!
          # when 3
          #   comments = field.nodes(:a).first

          #   # chapter_info["comments_url"] = comments.attributes["href"] || "/chapter/#{chapter_info["id"]}/comments"
          #   # chapter_info["comments"] = comments.scope.nodes(:span).first.inner_text.strip || "0"

          #   puts comments
          when 4
            chapter_info["uploaded"] = n.attribute_by("title").not_nil!
          when 6
            chapter_info["language"] = field.nodes(:span).first.attribute_by("title").not_nil!
          when 7
            group_arr = [] of Hash(String, FieldType)

            field.nodes(:a).each do |t|
              group = Hash(String, FieldType).new

              group["name"] = t.inner_text
              group["url"] = t.attributes["href"]
              group["id"] = parse_path(t.attributes["href"])[1].to_i

              group_arr << group
            end

            chapter_info["translation_groups"] = group_arr.map { |g| g.as(FieldType) }
          when 8
            uploader_node = field.nodes(:a).first
            uploader = Hash(String, FieldType).new
            uploader["name"] = uploader_node.inner_text
            uploader["url"] = uploader_node.attributes["href"]
            uploader["id"] = parse_path(uploader_node.attributes["href"])[1].to_i

            chapter_info["uploader"] = uploader
          when 9
            views = field.nodes(:span).first
            chapter_info["views"] = parse_int(views.inner_text)
          end
        end

        manga_chapters.push(chapter_info)
      end
      manga_chapters.map { |c| c.as(FieldType) }
    end

    def self.parse_manga_chapters_pagination(html)
      chap_info_text = html.css("p.mt-3.text-center").map(&.inner_text).to_a[0]
      chapter_info = chap_info_text.clone.gsub(/\b(Showing|to|of|chapters)\b/, "").split(" ").select { |x| x.size != 0 }

      pages = parse_int(chapter_info[2]) / parse_int(chapter_info[1])
      remainder = parse_int(chapter_info[2]) % parse_int(chapter_info[1])

      data["chapter_list_max_results"] = parse_int(chapter_info[1])
      data["total_chapters"] = parse_int(chapter_info[2])
      data["chapter_pages_per_result"] = (remainder != 0 ? pages+1 : pages)
    end
  end
end
