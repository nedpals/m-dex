module Mdex::Endpoints
  class Genre

    @@genre = Hash(String, String | Int32 | Array(Hash(String, String))).new

    def self.get(id : Int32)
      response = Mdex::Client.get("genre/#{id}")
      html = Myhtml::Parser.new(response.body)
      manga_list = [] of Hash(String, String)

      @@genre["id"] = id

      genre_card = html.css(".card").map(&.children).to_a[0]

      genre_card.each_with_index do |card_node, card_node_idx|
        case card_node_idx
        when 1
          @@genre["name"] = card_node.inner_text.lchop
        when 3
          @@genre["description"] = card_node.inner_text.strip
        end
      end

      html.css(".row.mt-1.mx-0 .manga-entry").each do |manga_node|
        manga = get_manga_info(manga_node)

        manga_list << manga
      end

      @@genre["manga_list"] = manga_list

      @@genre.to_json
    end

    private def self.get_manga_info(node)
      manga_info = Hash(String, String).new

      # manga_info["id"] = node.attribute_by("data-id")

      node.children.each_with_index do |info_node, info_node_idx|
        case info_node_idx
        when 1
          manga_info["cover_image"] = "#{Mdex::Client.base_url}#{info_node.scope.nodes(:img).to_a[0].attribute_by("src")}"
        when 3
          info_node_children = info_node.children.to_a

          # manga_info["language"] = info_node_children[1].child!.attribute_by("title")
          manga_info["title"] = info_node_children[3].inner_text
        when 5
          info_node.scope.nodes(:li).each_with_index do |stats, stats_idx|
            case stats_idx
            when 0
              manga_info["bayesian_rating"] = stats.scope.nodes(:span).to_a[2].inner_text.lchop
              manga_info["total_votes"] = stats.scope.nodes(:span).to_a[2].attribute_by("title").not_nil!.rchop(" votes").lchop
            when 1
              manga_info["follows"] = stats.inner_text.lchop
            when 2
              manga_info["views"] = stats.inner_text.lchop
            end
          end
        when 7
          manga_info["description"] = info_node.inner_text.strip
        end
      end

      manga_info
    end
  end
end
