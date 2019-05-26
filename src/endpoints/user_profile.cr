module Mdex::Endpoints
  class User
    alias UserGroups = Array(Hash(String, String | Int32))
    alias UserInfo = UserGroups | String | Int32 | Nil

    @@user = Hash(String, UserInfo).new

    def self.get(id : Int32)
      response = Mdex::Client.get("user/#{id}")
      html = Myhtml::Parser.new(response.body)

      error_banner = html.css(".alert.alert-danger.text-center")

      if (id > 0 || error_banner.to_a.size == 0)
        @@user["id"] = id

        parse_data(html)
      else
        {
          error_code: 404,
          message: error_banner.map(&.inner_text).to_a.join("").to_s
        }.to_json
      end
    end

    private def self.parse_data(html)
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
      avatar_img = node.children.to_a[1].children.to_a[1].child!
      @@user["avatar_url"] = "#{Mdex::Client.base_url}#{avatar_img.attribute_by("src").not_nil!.lchop}"

      node.children.to_a[1].children.to_a[3].children.to_a.each_with_index do |child_node, child_node_idx|
        if (child_node_idx % 2 == 1)
          child_nodes = child_node.children.to_a.select { |x| x.tag_name == "div" }

          case child_nodes[0].inner_text.rchop.downcase
          when "user level"
            @@user["level"] = child_nodes[1].inner_text.lchop
          when "joined"
            @@user["joined"] = child_nodes[1].inner_text.lchop
          when "last online"
            @@user["last_active"] = child_nodes[1].inner_text.lchop
          when "website"
            @@user["website"] = child_nodes[1].scope.nodes(:a).to_a[0].attribute_by("href")
          when "group(s)"
            joined_groups = [] of Hash(String, String | Int32)

            child_nodes[1].scope.nodes(:a).each do |user_group|
              joined_groups << {
                "name" => user_group.inner_text,
                "link" => user_group.attribute_by("href").not_nil!,
                "id" => user_group.attribute_by("href").not_nil!.split("/", remove_empty: true)[1].to_i
              }
            end

            @@user["groups"] = joined_groups
          when "stats"
            child_nodes[1].scope.nodes(:li).each_with_index do |user_stat, user_stat_idx|
              case user_stat_idx
              when 0
                @@user["views"] = user_stat.inner_text.lchop.tr(",", "").to_i
              when 1
                @@user["chapters_uploaded"] = user_stat.inner_text.lchop.tr(",", "").to_i
              end
            end
          when "biography"
            @@user["biography"] = child_nodes[1].inner_text
          end
        end
      end
    end
  end
end
