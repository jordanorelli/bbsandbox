require 'parslet/rig/rspec'
require_relative '../../bristlecode.rb'

module Bristlecode

  describe '.to_html' do

    def to_html(text)
      Bristlecode.to_html(text)
    end

    it 'leaves an empty string unchanged' do
      expect(to_html("")).to eq("")
    end

    it 'handles empty documents' do
      expect(to_html("      \t   \n    \n     \t")).to eq("")
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
      expected = '<b>bold<i>italic</i>bold</b>'
      out = to_html(doc)
      expect(out).to eq(expected)

      doc = '[i] italic [b] bold [/b] italic [/i]'
      expected = '<i>italic<b>bold</b>italic</i>'
      out = to_html(doc)
      expect(out).to eq(expected)
    end

    it 'auto-closes tags at eof' do
      expect(to_html("[b]bold")).to eq("<b>bold</b>")
      expect(to_html("[i]italic")).to eq("<i>italic</i>")
    end

    it 'can render simple links' do
      input = '[url]example.com[/url]'
      output = '<a href="example.com">example.com</a>'
      expect(to_html(input)).to eq(output)

      input = '[url]    example.com    [/url]'
      output = '<a href="example.com">example.com</a>'
      expect(to_html(input)).to eq(output)
    end

    it 'passes simple url contents opaquely' do
      input = '[url]x[b]y[/b]z[/url]'
      output = '<a href="x[b]y[/b]z">x[b]y[/b]z</a>'
      expect(to_html(input)).to eq(output)
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
      end

      it "doesn't die on elements nested in simple urls" do
        expect(parser.url).to parse('[url]goog[b]le.c[/b]om[/url]')
      end

      it 'fails nested [url] tags' do
        expect(parser.url).not_to parse('[url]x[url]y[/url]z[/url]')
      end
    end
  end
end
