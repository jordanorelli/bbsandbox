require 'parslet'
require 'sanitize'

module Bristlecode

  def Bristlecode.to_html(text)
    parser = Bristlecode::Parser.new
    parse_tree = parser.parse(text)
    tree = Bristlecode::Transform.new.apply(parse_tree)
    tree.to_html
  end

  def Bristlecode.clean(text)
    text.gsub!('&', '&amp;')
    text.gsub!('<', '&lt;')
    text.gsub!('>', '&gt;')
    text.gsub!('"', '&quot;')
    text.gsub!("'", '&#x27;')
    text.gsub!('/', '&#x2F;')
  end

  class Parser < Parslet::Parser
    rule(:space) { match('\s').repeat(1) }
    rule(:space?) { space.maybe }

    rule(:bold_open) { str('[b]') | str('[B]') }
    rule(:bold_close) { str('[/b]') | str('[/B]') | eof }
    rule(:bold) { bold_open >> children.as(:bold) >> bold_close }

    rule(:linebreak) { str('[br]').as(:br) }

    rule(:italic_open) { str('[i]') | str('[I]') }
    rule(:italic_close) { str('[/i]') | str('[/I]') | eof }
    rule(:italic) { italic_open >> children.as(:italic) >> italic_close }

    rule(:url_open) { str('[url]') }
    rule(:url_close) { str('[/url]') | eof }
    rule(:simple_href) { (url_close.absent? >> any).repeat }
    rule(:simple_url) { url_open >> simple_href.as(:href) >> url_close }
    rule(:url_title_open) { str('[url=') }
    rule(:url_title_href) { (match(']').absent? >> any).repeat }
    rule(:url_with_title) {
      url_title_open >>
      url_title_href.as(:href) >>
      match(']') >>
      children.as(:title) >>
      url_close
    }
    rule(:url) { (simple_url | url_with_title).as(:url) }

    rule(:eof) { any.absent? }
    rule(:tag) { bold | italic | url | linebreak }
    rule(:elem) { text.as(:text) | tag }
    rule(:tag_open) { bold_open | italic_open | url_open | url_title_open }
    rule(:tag_close) { bold_close | italic_close | url_close }
    rule(:tag_delim) { tag_open | tag_close | linebreak }

    rule(:text) { (tag_delim.absent? >> any).repeat(1) }
    rule(:children) { space? >> elem.repeat }
    rule(:doc) { space? >> elem.repeat.as(:doc) }
    root(:doc)
  end

  class Transform < Parslet::Transform
    rule(bold: sequence(:children)) { Bold.new(children) }
    rule(italic: sequence(:children)) { Italic.new(children) }
    rule(text: simple(:text)) { Text.new(text) }
    rule(doc: subtree(:doc)) { Doc.new(doc) }
    rule(url: subtree(:url)) { Url.new(url) }
    rule(br: simple(:br)) { Linebreak.new }
  end

  class Doc
    attr_accessor :children

    def initialize(children)
      self.children = children
    end

    def to_html
      s = StringIO.new
      children.each{|child| s << child.to_html }
      s.string
    end
  end

  class Text
    attr_accessor :text

    def initialize(text)
      self.text = text.to_str.strip
      Bristlecode.clean(self.text)
    end

    def to_html
      text
    end
  end

  class Bold
    attr_accessor :children

    def initialize(children)
      self.children = Doc.new(children)
    end

    def to_html
      "<b>#{children.to_html}</b>"
    end
  end

  class Italic
    attr_accessor :children

    def initialize(children)
      self.children = Doc.new(children)
    end

    def to_html
      "<i>#{children.to_html}</i>"
    end
  end

  class Url
    attr_accessor :href, :title

    def initialize(args)
      self.href = args[:href].to_str.strip
      check_href
      if args.has_key? :title
        self.title = Doc.new(args[:title])
      else
        self.title = Text.new(href)
      end
    end

    def check_href
      unless href =~ /^(\/[^\/]|https?:\/\/)/
        raise "href must start with /, http, or https"
      end
    end

    def to_html
      "<a href=\"#{href}\">#{title.to_html}</a>"
    end
  end

  class Linebreak
    def to_html
      "<br>"
    end
  end
end
