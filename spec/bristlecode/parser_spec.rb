require 'parslet/rig/rspec'
require_relative '../../bristlecode.rb'

module Bristlecode
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
  end
end
