require 'parslet'

module Bristlecode

  def Bristlecode.to_html(text)
    parser = Bristlecode::Parser.new
    parse_tree = parser.parse(text)
    tree = Bristlecode::Transform.new.apply(parse_tree)
    tree.to_html
  end

  class Parser < Parslet::Parser
    rule(:space) { match('\s').repeat(1) }
    rule(:space?) { space.maybe }

    rule(:bold_open) { str('[b]') | str('[B]') }
    rule(:bold_close) { str('[/b]') | str('[/B]') | eof }
    rule(:bold) { bold_open >> children.as(:bold) >> bold_close }

    rule(:italic_open) { str('[i]') | str('[I]') }
    rule(:italic_close) { str('[/i]') | str('[/I]') | eof }
    rule(:italic) { italic_open >> children.as(:italic) >> italic_close }

    rule(:eof) { any.absent? }
    rule(:tag) { bold | italic }
    rule(:elem) { text | tag }
    rule(:tag_open) { bold_open | italic_open }
    rule(:tag_close) { bold_close | italic_close }
    rule(:tag_delim) { tag_open | tag_close }

    rule(:text) { (tag_delim.absent? >> any).repeat(1).as(:text) }
    rule(:children) { space? >> elem.repeat(1) }
    rule(:doc) { space? >> elem.repeat.as(:doc) }
    root(:doc)
  end

  class Transform < Parslet::Transform
    rule(bold: sequence(:children)) { Bold.new(children) }
    rule(italic: sequence(:children)) { Italic.new(children) }
    rule(text: simple(:text)) { Text.new(text) }
    rule(doc: subtree(:doc)) { Doc.new(doc) }
  end

  class Doc
    def initialize(children)
      @children = children
    end

    def to_html
      s = StringIO.new
      @children.each{|child| s << child.to_html }
      s.string
    end
  end

  class Text
    def initialize(text)
      @text = text
    end

    def to_html
      @text
    end
  end

  class Bold
    def initialize(children)    
      @children = children
    end

    def to_html
      s = StringIO.new
      s << "<b>"
      @children.each{|child| s << child.to_html }
      s << "</b>"
      s.string
    end
  end

  class Italic
    def initialize(children)
      @children = children
    end

    def to_html
      s = StringIO.new
      s << "<i>"
      @children.each{|child| s << child.to_html }
      s << "</i>"
      s.string
    end
  end
end
