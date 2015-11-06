require 'parslet'
require 'sanitize'
require 'uri'

module Bristlecode

  class YoutubeFilter
    def call(env)
      node = env[:node]
      node_name = env[:node_name]
      return if env[:is_whitelisted] || !node.element?
      return unless node_name == 'iframe'
      return unless node['src'] =~ %r|\A(?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/|
      Sanitize.node!(node, {
        :elements => %w[iframe],
        :attributes => {'iframe'  => %w[allowfullscreen frameborder height src width]}
      })
      {:node_whitelist => [node]}
    end
  end

  class TweetFilter
    def call(env)
      node = env[:node]
      node_name = env[:node_name]
      return if env[:is_whitelisted] || !node.element?
      case node_name
      when 'script'
        return script env
      when 'blockquote'
        return blockquote env
      else
        return
      end
    end

    def script(env)
      node = env[:node]
      return unless node['src'] == "//platform.twitter.com/widgets.js"
      Sanitize.node!(node, {
        :elements => %w[script],
        :attributes => {'script'  => %w[aync src charset]}
      })
      {:node_whitelist => [node]}
    end

    def blockquote(env)
      node = env[:node]
      Sanitize.node!(node, {
        :elements => %w[blockquote a],
        :attributes => {'blockquote'  => ['class'], 'a' => ['href']}
      })
      {:node_whitelist => [node]}
    end
  end

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
    },
    :transformers => [YoutubeFilter.new, TweetFilter.new],
    :remove_contents => ['script']
  )

  def Bristlecode.to_html(text)
    begin
      parser = Bristlecode::Parser.new
      parse_tree = parser.parse(text)
      tree = Bristlecode::Transform.new.apply(parse_tree)
      html = tree.to_html
    rescue Parslet::ParseFailed => parse_error
      html = text
    end
    Bristlecode.sanitize_html(html)
  end

  def Bristlecode.sanitize_html(html)
    Sanitize.fragment(html, Bristlecode::Config)
  end

  def Bristlecode.clean!(text)
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
    rule(:url_title_href) { (match(']').absent? >> any).repeat(1) }
    rule(:url_with_title) {
      url_title_open >>
      url_title_href.as(:href) >>
      match(']') >>
      children.as(:title) >>
      url_close
    }
    rule(:url) { (simple_url | url_with_title).as(:url) }

    rule(:youtube_open) { str('[youtube]') }
    rule(:youtube_close) { str('[/youtube]') }
    rule(:youtube_url) { (youtube_close.absent? >> any).repeat(1) }
    rule(:youtube) { (youtube_open >> youtube_url.as(:src) >> youtube_close).as(:youtube) }

    rule(:tweet_open) { str('[tweet]') }
    rule(:tweet_close) { str('[/tweet]') }
    rule(:tweet_url) { (tweet_close.absent? >> any).repeat(1) }
    rule(:tweet) { (tweet_open >> tweet_url.as(:src) >> tweet_close).as(:tweet) }

    rule(:img_open) { str('[img]') }
    rule(:img_close) { str('[/img]') }
    rule(:img_src) { (img_close.absent? >> any).repeat(1) }
    rule(:img) { (img_open >> img_src.as(:src) >> img_close).as(:img) }

    rule(:eof) { any.absent? }
    rule(:tag) { bold | italic | url | linebreak | img | youtube | tweet }
    rule(:elem) { text.as(:text) | tag }
    rule(:tag_open) { bold_open | italic_open | url_open | url_title_open | img_open |
      youtube_open | tweet_open }
    rule(:tag_close) { bold_close | italic_close | url_close | img_close | youtube_close |
      tweet_close }
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
    rule(youtube: subtree(:youtube)) { Youtube.new(youtube) }
    rule(tweet: subtree(:tweet)) { Tweet.new(tweet) }
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

    def to_text
      s = StringIO.new
      children.each{|child| s << child.to_text }
      s.string
    end
  end

  class Text
    attr_accessor :text

    def initialize(text)
      self.text = text.to_str
      Bristlecode.clean!(self.text)
    end

    def to_html
      text
    end

    def to_text
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

    def to_text
      "[b]#{children.to_text}[/b]"
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

    def to_text
      "[i]#{children.to_text}[/i]"
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
        self.title = Text.new(args[:href].to_str.strip)
      end
    end

    def href_ok?
      href =~ /^(\/|https?:\/\/)/
    end

    def to_html
      return to_text unless href_ok?
      "<a href=\"#{href}\">#{title.to_html}</a>"
    end

    def to_text
      if title_supplied
        "[url=#{href}]#{title.to_text}[/url]"
      else
        text = "[url]#{href}[/url]"
        Bristlecode.clean!(text)
        text
      end
    end
  end

  class Linebreak
    def to_html
      "<br>"
    end

    def to_text
      "[br]"
    end
  end

  class Img
    attr_accessor :src

    def initialize(img)
      self.src = img[:src].to_str
    end

    def src_ok?
      src =~ /^(\/|https?:\/\/)/
    end

    def to_html
      return to_text unless src_ok?
      "<img src=\"#{src}\">"
    end

    def to_text
        text = "[img]#{src}[/img]"
        Bristlecode.clean!(text)
        text
    end
  end

  class Youtube
    attr_accessor :raw_url, :video_id

    def initialize(args)
      self.raw_url = args[:src].to_str.strip
      self.video_id = parse_url
    end

    def parse_url
      begin
        uri = URI::parse(raw_url)
        return false unless ['http', 'https'].include? uri.scheme
        return false unless ['www.youtube.com', 'youtube.com', 'youtu.be'].include? uri.host
        if uri.host == 'youtu.be'
          return uri.path[1..-1]
        else
          URI::decode_www_form(uri.query).each{|key, value| return value if key == 'v'}
        end
      rescue URI::InvalidURIError
      end

      return false
    end

    def to_html
      return to_text unless video_id
      "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube.com/embed/#{video_id}\" frameborder=\"0\" allowfullscreen></iframe>"
    end

    def to_text
      text = "[youtube]#{raw_url}[/youtube]"
      Bristlecode.clean!(text)
      text
    end
  end

  class Tweet
    attr_accessor :raw_url, :tweet_url

    def initialize(tweet)
      self.raw_url = tweet[:src].to_str.strip
      self.tweet_url = parse_url(self.raw_url)
    end

    def parse_url(url_in)
      begin
        uri = URI::parse(url_in)
        return false unless ['http', 'https'].include? uri.scheme
        return false unless uri.host == 'twitter.com'
        return false unless uri.path =~ /^\/[^\/]+\/status\/\d+/
        # strip querystring and fragment
        return "#{uri.scheme}://#{uri.host}#{uri.path}"
      rescue URI::InvalidURIError
      end
      return false
    end

    def to_html
      return to_text unless tweet_url
      "<blockquote class=\"twitter-tweet\"><a href=\"#{tweet_url}\"></a></blockquote><script async src=\"//platform.twitter.com/widgets.js\" charset=\"utf-8\"></script>"
    end

    def to_text
      text = "[tweet]#{raw_url}[/tweet]"
      Bristlecode.clean!(text)
      text
    end
  end
end
