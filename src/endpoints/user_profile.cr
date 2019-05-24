module Mdex::Endpoints
  class User
    alias UserGroups = Array(String)
    alias UserInfo = UserGroups | String | Int32 | Nil

    @@user = Hash(String, UserInfo).new

    def self.get(id : Int32)
      response = Mdex::Client.get("user/#{id}")
      html = Myhtml::Parser.new(response.body)

      @@user["id"] = id

      card_nodes = html.css(".card").map(&.children).to_a

      # Get @@user name and cover image
      card_nodes[0].each do |node|
        if (node.attribute_by("class") == "card-header d-flex align-items-center py-2")
          parse_username_and_avatar(node)
        end

        if (node.attribute_by("class") == "card-body p-0")
          parse_user_info(node)
        end
      end

      ## TODO: ADD RECENT CHAPTERS SECTION

      @@user.to_json
    end

    private def self.parse_username_and_avatar(node)
      node.scope.nodes(:span).each do |span_node|
        case span_node.attribute_by("class")
        when "mx-1"
          @@user["username"] = span_node.inner_text
        when "rounded flag"
          @@user["language"] = span_node.attribute_by("title")
        end
      end
    end

    private def self.parse_user_info(node)
      node.children.to_a[1].children.each_with_index do |child_node, child_node_idx|
        case child_node_idx
        when 1
          @@user["avatar_url"] = "#{Mdex::Client.base_url}#{child_node.child!.attribute_by("src")}"
        when 3
          child_node.children.each_with_index do |info_node, info_node_idx|
            info_node_children = info_node.children.to_a
            case info_node_idx
            when 1
              @@user["level"] = info_node_children[3].inner_text.lchop
            when 3
              @@user["date_joined"] = info_node_children[3].inner_text.lchop
            when 5
              @@user["last_online"] = info_node_children[3].inner_text.lchop
            when 7
              joined_groups = [] of String

              info_node_children[3].scope.nodes(:li).each do |user_group|
                joined_groups << user_group.inner_text.lchop
              end

              @@user["groups"] = joined_groups
            when 9
              info_node_children[3].scope.nodes(:li).each_with_index do |user_stat, user_stat_idx|
                case user_stat_idx
                when 0
                  @@user["views"] = user_stat.inner_text.lchop
                when 1
                  @@user["chapters_uploaded"] = user_stat.inner_text.lchop
                end
              end
            end
          end
        end
      end
    end
  end
end
