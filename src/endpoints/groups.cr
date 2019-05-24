module Mdex::Endpoints
  class Group
    alias GroupLinks = Hash(String | Nil, String | Nil)
    alias GroupMember = String
    alias GroupInfo = GroupLinks | Array(GroupMember) | String | Int32 | Nil

    @@group = Hash(String, GroupInfo).new

    def self.get(id : Int32)
      response = Mdex::Client.get("group/#{id}")
      html = Myhtml::Parser.new(response.body)
      @@group["id"] = id

      card_nodes = html.css(".card").map(&.children).to_a

      parse_group_name_and_cover(card_nodes[0])
      parse_additional_group_info(card_nodes[1])
      parse_group_member_info(card_nodes[2])

      # if (card_nodes[3]?)
      #   card_nodes[3].each do |node|
      #     if (node.attribute_by("class") == "card-body")
      #       @@group["description"] == node.to_html
      #     end
      #   end
      # end

      ## TODO: ADD RECENT CHAPTERS SECTION

      @@group.to_json
    end

    private def self.parse_group_name_and_cover(nodes)
      # Get @@group name and cover image
      nodes.each do |node|
        if (node.attribute_by("class") == "card-header d-flex align-items-center py-2")
          node.scope.nodes(:span).each do |span_node|
            case span_node.attribute_by("class")
            when "mx-1"
              @@group["name"] = span_node.inner_text
            when "rounded flag"
              @@group["language"] = span_node.attribute_by("title")
            end
          end
        end

        if (node.attribute_by("class") == "card-img-bottom")
          @@group["cover_image"] = node.attribute_by("src")
        end
      end
    end

    private def self.parse_additional_group_info(nodes)
      # Get @@group info
      nodes.each do |node|
        if (node.attribute_by("class") == "table table-sm ")
          node.scope.nodes(:td).each_with_index do |td_node, td_idx|
            case td_idx
            when 0
              @@group["alternate_names"] = td_node.inner_text
            when 1
              td_stats = td_node.scope.nodes(:li).map(&.inner_text).to_a

              @@group["views"] = td_stats[0].lstrip
              @@group["follows"] = td_stats[1].lstrip
              @@group["total_chapters"] = td_stats[2].lstrip
            when 2
              group_links = {} of String | Nil => String | Nil

              td_node.scope.nodes(:a).each do |link|
                link_title = link.child!.attribute_by("title")

                group_links[link_title] = link.attribute_by("href")
              end

              @@group["links"] = group_links
            # when 3
              ## TODO: Add follow link
            end
          end
        end
      end
    end

    private def self.parse_group_member_info(nodes)
      nodes.each do |node|
        if (node.attribute_by("class") == "table table-sm ")
          node.scope.nodes(:td).each_with_index do |td_node, td_idx|
            case td_idx
            when 0
              a_link = td_node.scope.nodes(:a).to_a[0]

              @@group["leader"] = a_link.inner_text
            when 1
              members = [] of GroupMember

              td_node.scope.nodes(:a).each do |link|
                members << link.inner_text
              end

              @@group["members"] = members
            when 2
              span_node = td_node.scope.nodes(:span).to_a[1]

              @@group["upload_restrictions"] = span_node.inner_text
            when 3
              @@group["upload_delay"] = td_node.child!.inner_text
            end
          end
        end
      end
    end
  end
end
