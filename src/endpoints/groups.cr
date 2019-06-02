module Mdex::Endpoints
  class Group < Mdex::Endpoint
    @@id = 0

    def self.get(@@id : Int32)
      super("group/#{@@id}")
    end

    def self.error_criteria
      @@id <= 0
    end

    def self.insert_ids(data)
      data["id"] = @@id
    end

    def self.parse_and_insert_data(data, html)
      card_nodes = html.css(".card").map(&.children).to_a.map do |child|
        child.select { |c| c.tag_name != "-text" }
      end

      parse_group_name_and_cover(card_nodes[0], data)
      parse_additional_group_info(card_nodes[1], data)
      parse_group_member_info(card_nodes[2], data)

      if (card_nodes[3]? != nil)
        data["description"] = card_nodes[3].to_a[1].children.map(&.to_html).to_a.join("")
      end

      ## TODO: ADD RECENT CHAPTERS SECTION
    end

    private def self.parse_group_name_and_cover(nodes, data)
      nodes.each do |node|
        if (node.attribute_by("class") == "card-header d-flex align-items-center py-2")
          node.scope.nodes(:span).each do |span_node|
            case span_node.attribute_by("class")
            when "mx-1"
              data["name"] = span_node.inner_text.not_nil!
            when "rounded flag"
              data["language"] = span_node.attribute_by("title").not_nil!
            end
          end
        end

        if (node.attribute_by("class") == "card-img-bottom")
          data["cover_image"] = "#{Mdex::Client.base_url}#{node.attribute_by("src").not_nil!.lchop}"
        end
      end
    end

    private def self.parse_additional_group_info(nodes, data)
      nodes.each do |node|
        if (node.attribute_by("class") == "table table-sm ")
          node.scope.nodes(:td).each_with_index do |td_node, td_idx|
            case td_idx
            when 0
              data["alternate_names"] = td_node.inner_text
            when 1
              td_stats = td_node.scope.nodes(:li).map(&.inner_text).to_a

              data["views"] = td_stats[0].lstrip.tr(",", "").to_i
              data["follows"] = td_stats[1].lstrip.tr(",", "").to_i
              data["total_chapters"] = td_stats[2].lstrip.tr(",", "").to_i
            when 2
              group_links = {} of String => FieldType

              td_node.scope.nodes(:a).each do |link|
                link_child = link.children.to_a.select { |x| x.tag_name == "span" }
                link_title = link_child[0].attribute_by("title").not_nil!

                group_links[link_title] = link.attribute_by("href").not_nil!
              end

              data["links"] = group_links
            # when 3
              ## TODO: Add follow link
            end
          end
        end
      end
    end

    private def self.parse_group_member_info(nodes, data)
      nodes.each do |node|
        if (node.attribute_by("class") == "table table-sm ")
          node.scope.nodes(:tr).each_with_index do |tr_node, tr_idx|
            tr_node_children = tr_node.children.to_a.select { |n| n.tag_name == "th" || n.tag_name == "td" }
            field_name = tr_node_children[0].inner_text.downcase.rchop
            td_node = tr_node_children[1]

            case field_name
            when "leader"
              a_link = td_node.scope.nodes(:a).to_a[0]

              data["leader"] = a_link.inner_text
            when "members"
              members = [] of FieldType

              td_node.scope.nodes(:a).each do |link|
                members << link.inner_text
              end

              data["members"] = members
            when "upload restrictions"
              span_node = td_node.scope.nodes(:span).to_a[1]

              data["upload_restrictions"] = span_node.inner_text
            when "group delay"
              data["upload_delay"] = td_node.child!.inner_text
            end
          end
        end
      end
    end
  end
end
