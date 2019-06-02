module MdexHelpers
  extend self

  def parse_int(str : String, remove_whitespace : String | Bool = false)
    if (remove_whitespace.is_a?(Bool))
      if (remove_whitespace)
        str = str.lchop.rchop
      end
    end

    if (remove_whitespace.is_a?(String))
      case remove_whitespace
      when "left"
        str = str.lchop
      when "right"
        str = str.rchop
      when "both"
        str = str.lchop.rchop
      else
        raise Exception.new("'remove_whitespace' must be 'left', 'right', 'both', or a boolean (true or false).")
      end
    end

    str.tr(",", "").to_i
  end

  def parse_float(str : String, remove_whitespace : String | Bool = false)
    if (remove_whitespace.is_a?(Bool))
      if (remove_whitespace)
        str = str.lchop.rchop
      end
    end

    if (remove_whitespace.is_a?(String))
      case remove_whitespace
      when "left"
        str = str.lchop
      when "right"
        str = str.rchop
      when "both"
        str = str.lchop.rchop
      else
        raise Exception.new("'remove_whitespace' must be 'left', 'right', 'both', or a boolean (true or false).")
      end
    end

    str.to_f
  end

  def parse_path(str : String) : Array(String)
    str.split("/", remove_empty: true)
  end
end
