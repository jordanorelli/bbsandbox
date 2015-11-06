require 'parslet'
require 'sanitize'

module Bristlecode

  Config = Sanitize::Config::freeze_config(
    :elements => %w[b em i strong u a strike br img],
    :attributes => {
      'a' => ['href'],
      'img' => ['src'],
    },
    :add_attributes => {
      'a' => {'rel' => 'nofollow'}
    },
    :protocols => {
      'a' => {'href' => ['http', 'https', :relative]}
    }
  )

  def Bristlecode.to_html(text)
    parser = Bristlecode::Parser.new
    parse_tree = parser.parse(text)
    tree = Bristlecode::Transform.new.apply(parse_tree)
    html = tree.to_html
    Sanitize.fragment(html, Bristlecode::Config)
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

    rule(:img_open) { str('[img]') }
    rule(:img_close) { str('[/img]') }
    rule(:img_src) { (img_close.absent? >> any).repeat(1) }
    rule(:img) { (img_open >> img_src.as(:src) >> img_close).as(:img) }

    rule(:eof) { any.absent? }
    rule(:tag) { bold | italic | url | linebreak | img }
    rule(:elem) { text.as(:text) | tag }
    rule(:tag_open) { bold_open | italic_open | url_open | url_title_open | img_open }
    rule(:tag_close) { bold_close | italic_close | url_close | img_close }
    rule(:tag_delim) { tag_open | tag_close | linebreak }

    rule(:text) { (tag_delim.absent? >> any).repeat(1) }
    rule(:children) { elem.repeat }
    rule(:doc) { elem.repeat.as(:doc) }
    root(:doc)
  end

  class Transform < Parslet::Transform
    rule(bold: sequence(:children)) { Bold.new(children) }
    rule(italic: sequence(:children)) { Italic.new(children) }
    rule(text: simple(:text)) { Text.new(text) }
    rule(doc: subtree(:doc)) { Doc.new(doc) }
    rule(url: subtree(:url)) { Url.new(url) }
    rule(br: simple(:br)) { Linebreak.new }
    rule(img: subtree(:img)) { Img.new(img) }
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
      self.text = text.to_str
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
    attr_accessor :href, :title, :bad_href, :title_supplied

    def initialize(args)
      self.href = args[:href].to_str.strip
      if args.has_key? :title
        self.title_supplied = true
        self.title = Doc.new(args[:title])
      else
        self.title_supplied = false
        self.title = Text.new(self.href)
      end
    end

    def href_ok?
      href =~ /^https?:/
    end

    def to_html
      if href_ok?
        "<a href=\"#{href}\">#{title.to_html}</a>"
      else
        reject
      end
    end

    def reject
      if title_supplied
        "[url=#{href}]#{title.to_html}[/url]"
      else
        Text.new("[url]#{href}[/url]").to_html
      end
    end
  end

  class Linebreak
    def to_html
      "<br>"
    end
  end

  class Img
    attr_accessor :src

    def initialize(img)
      self.src = img[:src].to_str
    end

    def src_ok?
      src =~ /^(\/[^\/]|https?:\/\/)/
    end

    def to_html
      if src_ok?
        "<img src=\"#{src}\">"
      else
        Text.new("[img]#{src}[/img]").to_html
      end
    end
  end
end
