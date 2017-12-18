# encoding: utf-8

require 'rspec-html-matchers'

require File.join(File.dirname(__FILE__), '..', 'lib', 'bing_translator')

describe BingTranslator do
  include RSpecHtmlMatchers
  let(:message_en) { "This message should be translated" }
  let(:message_en_other) { "This message should be too translated" }
  let(:long_text) { File.read(File.join(File.dirname(__FILE__), 'long_text')) }
  let(:long_unicode_text) { File.read(File.join(File.dirname(__FILE__), 'long_unicode_text.txt')) }
  let(:long_html_text) { File.read(File.join(File.dirname(__FILE__), 'long_text.html')) }
  let(:translator) {
    BingTranslator.new(ENV['COGNITIVE_SUBSCRIPTION_KEY'],
      skip_ssl_verify: false)
  }

  it "translates text" do
    result = translator.translate message_en, :from => :en, :to => :ru
    result.should == "Это сообщение должно быть переведено"

    result = translator.translate message_en, :from => :en, :to => :fr
    result.should == "Ce message devrait être traduit"

    result = translator.translate message_en, :from => :en, :to => :de
    result.should == "Diese Meldung sollte übersetzt werden"
  end

  it "translates long texts (up to allowed limit)" do
    result = translator.translate long_text, :from => :en, :to => :ru
    result.size.should > 1000

    result = translator.translate long_unicode_text, :from => :ru, :to => :en
    result.size.should > 5000 # I assume that the translation couldn't be two times smaller, than the original
  end

  it "translates texts in html" do
    result = translator.translate long_html_text, :from => :en, :to => :ru, :content_type => 'text/html'
    result.size.should > 1000
    result.to_s.should have_tag('p')
    result.to_s.should have_tag('code')
  end

  it "translates text with language autodetection" do
    result = translator.translate message_en, :to => :ru
    result.should == "Это сообщение должно быть переведено"

    result = translator.translate "Ce message devrait être traduit", :to => :en
    result.should == message_en

    result = translator.translate "Diese Meldung sollte übersetzt werden", :to => :en
    result.should == message_en
  end

  it "translates array of texts" do
    result = translator.translate_array [message_en, message_en_other], :from => :en, :to => :fr
    result.should == ["Ce message devrait être traduit", "Ce message devrait être aussi traduit"]
  end

  it "translates array of texts, with word alignment information" do
    result = translator.translate_array2 [message_en, message_en_other], :from => :en, :to => :de
    result.should == [["Diese Meldung sollte übersetzt werden",
                       "0:3-0:4 5:11-6:12 13:18-14:19 20:21-31:36 23:32-21:29"],
                      ["Diese Meldung sollte auch übersetzt werden",
                       "0:3-0:4 5:11-6:12 13:18-14:19 20:21-36:41 23:25-21:24 27:36-26:34"]]
  end

  it "detects language by passed text" do
    result = translator.detect message_en
    result.should == :en

    result = translator.detect ' '
    result.should == nil

    result = translator.detect "Это сообщение должно быть переведено"
    result.should == :ru

    result = translator.detect "Diese Meldung sollte übersetzt werden"
    result.should == :de
  end

  it "returns audio data from the text to speech interface" do
    result = translator.speak message_en, :language => 'en'
    result.length.should > 1000

    result = translator.speak "Это сообщение должно быть переведены", :language => 'ru'
    result.length.should > 1000

    result = translator.speak "Ce message devrait être traduit", :language => 'fr'
    result.length.should > 1000

    result = translator.speak "Diese Meldung sollte übersetzt werden", :language => 'de'
    result.length.should > 1000

    result = translator.speak "Diese Meldung sollte übersetzt werden", :language => 'de', :format => 'audio/wav', :options => 'MaxQuality'
    result.length.should > 1000
  end

  it "throws a reasonable error when the Bing translate API returns an error" do
    expect { translator.translate 'hola', :from => :invlaid, :to => :en }.to raise_error(BingTranslator::Exception)
  end

  it "is able to list languages that the API supports" do
    result = translator.supported_language_codes
    result.include?('en').should == true
  end

  it "is able to get language names from language codes" do
    translator.language_names(['en', 'es', 'de']).should == ['English', 'Spanish', 'German']
    translator.language_names(['en', 'es', 'de'], 'de').should == ['Englisch', 'Spanisch', 'Deutsch']
  end

  context 'when credentials are invalid' do
    let(:translator) { BingTranslator.new("") }

    subject { translator.translate 'hola', :from => :es, :to => :en }

    it "throws a BingTranslator::Exception exception" do
      expect { subject }.to raise_error(BingTranslator::Exception)
    end

    context "trying to translate something twice" do
      it "throws the BingTranslator::Exception exception every time" do
        2.times { expect { subject }.to raise_error(BingTranslator::Exception) }
      end
    end
  end
end
