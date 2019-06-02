require "uri"
require "json"

module Mdex::Endpoints
  class Manga < Mdex::Endpoint
    @@id = 0
    @@title_slug = ""

    def self.get(@@id : Int32, @@title_slug : String)
      super("title/#{@@id}")
    end

    def self.error_criteria
      @@id <= 0
    end

    def self.insert_ids(data)
      data["id"] = @@id
    end

    def self.parse_and_insert_data(data, html)
      # Get manga cover image
      cover_photo_path = html.css(".card-body .row .col-xl-3 img").map(&.attribute_by("src")).to_a[0]
      data["cover_photo"] = "#{Mdex::Client.base_url}#{cover_photo_path.not_nil!.lchop}"

      # Get manga name
      data["name"] = html.css(".card .card-header span:nth-child(2)").map(&.inner_text).to_a[0]

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
            data["alternate_names"] = parse_alt_names(node)
          when "author"
            data["author"] = parse_name(node)
          when "artist"
            data["artist"] = parse_name(node)
          when "demographic"
            data["demographics"] = parse_demographic(node)
          when "format"
            data["format"] = parse_tags(node)
          when "genre"
            data["genre"] = parse_genre(node)
          when "official"
            data["official"] = parse_links(node)
          when "rating"
            ratings_arr = parse_ratings(node)

            data["bayesian_rating"] = ratings_arr[0]
            data["mean_rating"] = ratings_arr[1]
            data["users_rated"] = ratings_arr[2]
          when "retail"
            data["retail"] = parse_links(node)
          when "pub. status"
            data["status"] = node.inner_text
          when "stats"
            stats_arr = parse_stats(node)

            data["views"] = stats_arr[0]
            data["follows"] = stats_arr[1]
            data["total_chapters"] = stats_arr[2]
          when "theme"
            data["theme"] = parse_tags(node)
          when "description"
            data["description"] = parse_description(node)
          when "information"
            data["links"] = parse_links(node)
          end
        end
      end

      if (html.css("p.mt-3.text-center").to_a.size != 0)
        parse_manga_chapters_pagination(html)
      end

      data["chapters"] = parse_manga_chapters(html)
    end

    private def self.parse_manga_chapters_pagination(html)
      Mdex::Endpoints::MangaChapters.parse_manga_chapters_pagination(html)
    end

    private def self.parse_manga_chapters(html)
      Mdex::Endpoints::MangaChapters.parse_chapters(html)
    end

    private def self.parse_alt_names(node)
      alt_names_ul = node.scope.nodes(:ul).first
      alt_names = alt_names_ul.scope.nodes(:li).map(&.inner_text).to_a

      alt_names.map { |n| n.strip.as(FieldType) }
    end

    private def self.parse_name(node)
      node.scope.nodes(:a).first.inner_text.strip
    end

    private def self.parse_demographic(node)
      node.scope.nodes(:span).map(&.inner_text).to_a.map { |d| d.as(FieldType) }
    end

    private def self.parse_tags(node)
      node.scope.nodes(:a).map(&.inner_text).to_a.map { |t| t.as(FieldType) }
    end

    private def self.parse_genre(node)
      genres_arr = [] of Hash(String, FieldType)
      node.scope.nodes(:a).each do |n|
        genre_href = n.attribute_by("href").not_nil!.to_s

        genre = {} of String => FieldType
        genre["name"] = n.inner_text
        genre["id"] = parse_path(genre_href)[1].to_i
        genres_arr << genre
      end

      genres_arr.map { |g| g.as(FieldType) }
    end

    private def self.parse_links(node)
      links_arr = [] of Hash(String, FieldType)
      node.scope.nodes(:ul).first.scope.nodes(:li).each do |link_node|
        link_node.scope.nodes(:a).each do |n|
          link_href = n.attribute_by("href").not_nil!
          link_name = n.inner_text
          link = {} of String => FieldType
          link[link_name] = link_href

          links_arr << link
        end
      end

      links_arr.map { |l| l.as(FieldType) }
    end

    private def self.parse_ratings(node)
      ratings_arr = [] of FieldType

      node.scope.nodes(:ul).first.scope.nodes(:li).each_with_index do |rating, rating_idx|
        if (rating.inner_text != "")
          if (rating_idx != 2)
            ratings_arr << parse_float(rating.inner_text.strip, false)
          else
            ratings_arr << parse_int(rating.inner_text)
          end
        end
      end

      ratings_arr.map { |r| r.as(FieldType) }
    end

    private def self.parse_stats(node)
      stats_arr = [] of FieldType

      node.scope.nodes(:ul).first.scope.nodes(:li).each do |stat_int|
        stats_arr << parse_int(stat_int.inner_text)
      end

      stats_arr.map { |s| s.as(FieldType) }
    end

    private def self.parse_description(node)
      node.children.map(&.to_html).to_a.join("")
    end
  end
end
