require_relative 'spec_helper'

describe BingTranslator do
  include RSpecHtmlMatchers

  def load_file(filename)
    File.read(File.join(File.dirname(__FILE__), 'etc', filename))
  end

  let(:message_en) do
    'This message should be translated'
  end

  let(:message_en_other) do
    'This message should be too translated'
  end

  let(:long_text) do
    load_file('long_text')
  end

  let(:long_unicode_text) do
    load_file('long_unicode_text.txt')
  end

  let(:long_html_text) do
    load_file('long_text.html')
  end

  let(:translator) do
    BingTranslator.new(ENV.fetch('COGNITIVE_SUBSCRIPTION_KEY'),
                       skip_ssl_verify: false)
  end

  describe '#translate' do
    it 'translates text' do
      result = translator.translate message_en, from: :en, to: :ru
      expect(result).to eq 'Это сообщение должно быть переведено'

      result = translator.translate message_en, from: :en, to: :fr
      expect(result).to eq 'Ce message doit être traduit'

      result = translator.translate message_en, from: :en, to: :de
      expect(result).to eq 'Diese Botschaft sollte übersetzt werden'
    end

    it 'translates long texts (up to allowed limit)' do
      result = translator.translate long_text, from: :en, to: :ru
      expect(result.size).to be > 1000

      result = translator.translate long_unicode_text, from: :ru, to: :en
      expect(result.size).to be > (long_unicode_text.size / 2) # I assume that the translation couldn't be two times smaller, than the original
    end

    it 'translates texts in html' do
      result = translator.translate long_html_text, from: :en, to: :ru, html: true
      expect(result.size).to be > 1000
      expect(result.to_s).to have_tag('p')
      expect(result.to_s).to have_tag('code')
    end

    it 'translates text with language autodetection' do
      result = translator.translate message_en, to: :ru
      expect(result).to eq 'Это сообщение должно быть переведено'

      result = translator.translate 'Ce message devrait être traduit', to: :en
      expect(result).to eq message_en

      result = translator.translate 'Diese Meldung sollte übersetzt werden', to: :en
      expect(result).to eq message_en
    end
  end

  it 'translates array of texts' do
    result = translator.translate_array [message_en, message_en_other], from: :en, to: :fr
    expect(result).to eq ['Ce message devrait être traduit', 'Ce message devrait être aussi traduit']
  end

  it 'translates array of texts, with word alignment information' do
    result = translator.translate_array2 [message_en, message_en_other], from: :en, to: :de
    expect(result).to eq [['Diese Meldung sollte übersetzt werden',
                           '0:3-0:4 5:11-6:12 13:18-14:19 20:21-31:36 23:32-21:29'],
                          ['Diese Meldung sollte auch übersetzt werden',
                           '0:3-0:4 5:11-6:12 13:18-14:19 20:21-36:41 23:25-21:24 27:36-26:34']]
  end

  it 'detects language by passed text' do
    result = translator.detect message_en
    expect(result).to eq :en

    result = translator.detect ' '
    expect(result).to be_nil

    result = translator.detect 'Это сообщение должно быть переведено'
    expect(result).to eq :ru

    result = translator.detect 'Diese Meldung sollte übersetzt werden'
    expect(result).to eq :de
  end

  it 'returns audio data from the text to speech interface' do
    result = translator.speak message_en, language: 'en'
    expect(result.size).to be > 1000

    result = translator.speak 'Это сообщение должно быть переведены', language: 'ru'
    expect(result.size).to be > 1000

    result = translator.speak 'Ce message devrait être traduit', language: 'fr'
    expect(result.size).to be > 1000

    result = translator.speak 'Diese Meldung sollte übersetzt werden', language: 'de'
    expect(result.size).to be > 1000

    result = translator.speak 'Diese Meldung sollte übersetzt werden', language: 'de', format: 'audio/wav', options: 'MaxQuality'
    expect(result.size).to be > 1000
  end

  it 'throws a reasonable error when the Bing translate API returns an error' do
    expect { translator.translate 'hola', from: :invlaid, to: :en }.to raise_error(BingTranslator::Exception)
  end

  it 'is able to list languages that the API supports' do
    result = translator.supported_language_codes
    expect(result).to include('en')
  end

  it 'is able to get language names from language codes' do
    expect(translator.language_names(%w[en es de])).to eq %w[English Spanish German]
    expect(translator.language_names(%w[en es de], 'de')).to eq %w[Englisch Spanisch Deutsch]
  end

  context 'when credentials are invalid' do
    let(:translator) { BingTranslator.new('') }

    subject { translator.translate 'hola', from: :es, to: :en }

    it 'throws a BingTranslator::Exception exception' do
      expect { subject }.to raise_error(BingTranslator::Exception)
    end

    context 'trying to translate something twice' do
      it 'throws the BingTranslator::Exception exception every time' do
        2.times { expect { subject }.to raise_error(BingTranslator::Exception) }
      end
    end
  end
end
