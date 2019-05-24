module Mdex::Endpoints
  class Search
    alias SearchField = Hash(String, String | Array(SearchField))
    alias SearchFields = Array(SearchField)
    alias SearchQuery = String
    alias SearchParams = Hash(String, String)

    alias SearchForm = SearchField | String | Nil

    def self.get(query : SearchQuery = "", options : SearchParams = {} of String => String, fields_only : Bool = false)
      response = Mdex::Client.get("search")
      html = Myhtml::Parser.new(response.body)
      search_form = Hash(String, SearchForm).new

      html.css("#search_titles_form").each do |form_node|
        search_form["method"] = form_node.attribute_by("method")
        search_form["action"] = "#{Mdex::Client.base_url}#{form_node.attribute_by("action")}"
      end

      if (fields_only == true)
          search_fields = [] of SearchField

        html.css("#search_titles_form .form-group.row").each do |field_node|
          search_field = {} of String => String
          children = field_node.children.to_a
          field = children[1].child!
          search_field["name"] = field.attribute_by("name")

          case field.tag_name
          when "select"
            select_options = [] of Hash(String, String)
            search_field["type"] = "select"

            field.children.each do |children_node|
              select_option = {} of String => String | SearchField

              if (children_node.attributes.has_key?("selected"))
                search_field["default_value"] = children_node.attribute_by("value")
              end

              if (children_node.tag_name == "optgroup")
                select_option["optgroup_values"] = [] of Hash(String, String | SearchField)
                select_option["optgroup_name"] = children_node.attribute_by("label")

                children_node.children.each do |option|
                  optgroup_select_option = {} of String => String | SearchField
                  optgroup_select_option["text"] = option.inner_text
                  optgroup_select_option["value"] = option.attribute_by("value")
                  select_option["optgroup_name"] << optgroup_select_option
                end
              else
                select_option["text"] = children_node.inner_text
                select_option["value"] = children_node.attribute_by("value")
                select_options << select_option
              end
            end

            search_field["options"] = select_options
          when "input"
            search_field["type"] = field.attribute_by("type")
            search_field["default_value"] = field.attribute_by("value")

            # if (field.attribute_by("type") == "radio")
            #   search_field["default_value"] = field.attribute_by("value")
            #   search_field["checked"] = field.attribute_by("checked")
            # else
            #   search_field["default_value"] = field.attribute_by("value")
            # end
          # when "div"
          #   if (field.attribute_by("class") == "form-check form-check-inline" && field.attribute_by("class") != "btn-group")
          #     field.scope.nodes(:input).each do |input_node|

          #     end

          #     search_field["default_value"] = field.attribute_by("value")
          #     search_field["checked"] = field.attribute_by("checked")
          #   end
          end

          # search_field["type"] = field.attribute_by("type") || field.tag_name
          # search_field["default_value"] = field.attribute_by("value")
        end

        puts search_form.to_json
      end
    end
  end
end
