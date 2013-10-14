# encoding: utf-8

require 'rspec-html-matchers'

require File.join(File.dirname(__FILE__), '..', 'lib', 'bing_translator')

# Log all the tasks output, keeping RSpec interface clean while running
RSpec.configure do |config|
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    # Redirect stderr and stdout
    $stderr = File.new(File.join(File.dirname(__FILE__), 'stderr.log'), 'w')
    $stdout = File.new(File.join(File.dirname(__FILE__), 'stdout.log'), 'w')
  end
  config.after(:all) do
    # Return stderr and stdout back in to the place
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

describe BingTranslator do
  let(:message_en) { "This message should be translated" }
  let(:long_text) { File.read(File.join(File.dirname(__FILE__), 'long_text')) }
  let(:long_unicode_text) { File.read(File.join(File.dirname(__FILE__), 'long_unicode_text.txt')) }
  let(:long_html_text) { File.read(File.join(File.dirname(__FILE__), 'long_text.html')) }
  let(:translator) {
    BingTranslator.new(ENV['BING_TRANSLATOR_TEST_CLIENT_ID'],
      ENV['BING_TRANSLATOR_TEST_CLIENT_SECRET'],
      false,
      ENV['AZURE_TEST_ACCOUNT_KEY'])
  }

  it "translates text" do
    result = translator.translate message_en, :from => :en, :to => :ru
    result.should == "Это сообщение должно быть переведены"

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
    result.should == "Это сообщение должно быть переведены"

    result = translator.translate "Ce message devrait être traduit", :to => :en
    result.should == message_en

    result = translator.translate "Diese Meldung sollte übersetzt werden", :to => :en
    result.should == message_en
  end

  it "detects language by passed text" do
    result = translator.detect message_en
    result.should == :en

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

  it "throws a BingTranslatorAuthenticationException exception on invalid credentials" do
    translator = BingTranslator.new("", "")
    expect { translator.translate 'hola', :from => :es, :to => :en }.to raise_error(BingTranslator::AuthenticationException)
  end

  describe "#balance" do
    context "when azure account key has been defined" do
      it "returns the balance" do
        balance = translator.balance

        balance.should be_a Fixnum
      end
    end

    context "when azure account has been defined" do
      let(:translator) { BingTranslator.new("", "") }

      it "raises an exception" do
        expect { translator.balance }.to raise_error
      end
    end
  end
end
