module Bristlecode
  class RootNode < Treetop::Runtime::SyntaxNode
    def to_html
      elements.each{|elem| elem.to_html} 
    end
  end

  class TextNode < Treetop::Runtime::SyntaxNode
    def initialize(input, interval, elements)
      @text = input[interval]
    end

    def text_value
      @text
    end

    def inspect(indent="")
      s = "#{indent}TextNode:\n"
      text_value.each_line{|line| s += "#{indent}  #{line}"}
      s
    end

    def to_html
      text_value 
    end
  end

  ##############################
  # bold
  ##############################

  class BoldNode < Treetop::Runtime::SyntaxNode
  end

  class BoldOpenNode < Treetop::Runtime::SyntaxNode
  end

  class BoldCloseNode < Treetop::Runtime::SyntaxNode
  end

  ##############################
  # italic
  ##############################

  class ItalicNode < Treetop::Runtime::SyntaxNode
  end

  class ItalicOpenNode < Treetop::Runtime::SyntaxNode
  end

  class ItalicCloseNode < Treetop::Runtime::SyntaxNode
  end

  class TagNode < Treetop::Runtime::SyntaxNode
  end
end
