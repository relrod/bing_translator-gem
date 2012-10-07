# encoding: utf-8
require File.join(File.dirname(__FILE__), '..', 'lib', 'bing_translator')

describe BingTranslator do
  before(:each) do
    @message_en = "This message should be translated"
    @translator = BingTranslator.new(ENV['BING_TRANSLATOR_TEST_CLIENT_ID'],
      ENV['BING_TRANSLATOR_TEST_CLIENT_SECRET'])
  end

  it "should translate text" do
    result = @translator.translate @message_en, :from => :en, :to => :ru
    result.should == "Это сообщение должно быть переведены"

    result = @translator.translate @message_en, :from => :en, :to => :fr
    result.should == "Ce message devrait être traduit."

    result = @translator.translate @message_en, :from => :en, :to => :de
    result.should == "Diese Meldung sollte übersetzt werden"
  end

  it "should translate text with language autodetection" do
    result = @translator.translate @message_en, :to => :ru
    result.should == "Это сообщение должно быть переведены"

    result = @translator.translate "Ce message devrait être traduit", :to => :en
    result.should == @message_en

    result = @translator.translate "Diese Meldung sollte übersetzt werden", :to => :en
    result.should == @message_en
  end

  it "should detect language by passed text" do
    result = @translator.detect @message_en
    result.should == :en

    result = @translator.detect "Это сообщение должно быть переведено"
    result.should == :ru

    result = @translator.detect "Diese Meldung sollte übersetzt werden"
    result.should == :de
  end

  it "should be able to list languages that the API supports" do
    result = @translator.supported_language_codes
    result.include?('en').should == true
  end
end
