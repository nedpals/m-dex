module Mdex::Endpoints
  class User < Mdex::Endpoint
    @@id = 0

    def self.get(@@id : Int32)
      super("user/#{@@id}")
    end

    def self.error_criteria
      @@id <= 0
    end

    def self.insert_ids(data)
      data["id"] = @@id
    end

    def self.parse_and_insert_data(data, html)
      card_nodes = html.css(".card").map(&.children).to_a

      # Get data name and cover image
      card_nodes[0].each do |node|
        if (node.attribute_by("class") == "card-header d-flex align-items-center py-2")
          parse_username_and_avatar(node, data)
        end

        if (node.attribute_by("class") == "card-body p-0")
          parse_user_info(node, data)
        end
      end

      ## TODO: ADD RECENT CHAPTERS SECTION
    end

    private def self.parse_username_and_avatar(node, data)
      node.scope.nodes(:span).each do |span_node|
        case span_node.attribute_by("class")
        when "mx-1"
          data["username"] = span_node.inner_text
        when "rounded flag"
          data["language"] = span_node.attribute_by("title").not_nil!
        end
      end
    end

    private def self.parse_user_info(node, data)
      avatar_img = node.children.to_a[1].children.to_a[1].child!
      data["avatar_url"] = "#{Mdex::Client.base_url}#{avatar_img.attribute_by("src").not_nil!.lchop}"

      node.children.to_a[1].children.to_a[3].children.to_a.each_with_index do |child_node, child_node_idx|
        if (child_node_idx % 2 == 1)
          child_nodes = child_node.children.to_a.select { |x| x.tag_name == "div" }

          case child_nodes[0].inner_text.rchop.downcase
          when "user level"
            data["level"] = child_nodes[1].inner_text.lchop
          when "joined"
            data["joined"] = child_nodes[1].inner_text.lchop
          when "last online"
            data["last_active"] = child_nodes[1].inner_text.lchop
          when "website"
            data["website"] = child_nodes[1].scope.nodes(:a).to_a[0].attribute_by("href").not_nil!
          when "group(s)"
            joined_groups = [] of Hash(String, FieldType)

            child_nodes[1].scope.nodes(:a).each do |user_group|
              group = Hash(String, FieldType).new
              group["name"] = user_group.inner_text
              group["link"] = user_group.attribute_by("href").not_nil!
              group["id"] = parse_path(user_group.attribute_by("href").not_nil!)[1].to_i

              joined_groups << group
            end

            data["groups"] = joined_groups.map { |g| g.as(FieldType) }
          when "stats"
            child_nodes[1].scope.nodes(:li).each_with_index do |user_stat, user_stat_idx|
              case user_stat_idx
              when 0
                data["views"] = parse_int(user_stat.inner_text, "left")
              when 1
                data["chapters_uploaded"] = parse_int(user_stat.inner_text, "left")
              end
            end
          when "biography"
            data["biography"] = child_nodes[1].children.map(&.to_html).to_a.join("")
          end
        end
      end
    end
  end
end
