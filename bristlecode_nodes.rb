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
      "#{indent}TextNode: #{text_value}"
    end

    def to_html
      text_value 
    end
  end

  class BoldOpenNode < Treetop::Runtime::SyntaxNode
  end

  class BoldCloseNode < Treetop::Runtime::SyntaxNode
  end

  class BoldNode < Treetop::Runtime::SyntaxNode
  end

  class TagNode < Treetop::Runtime::SyntaxNode
  end
end
