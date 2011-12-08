Bing Translator
===============

This gem wraps the Micrsoft Bing HTTP Translate API.
I am in no way affiliated with Microsoft or Bing.
Use this gem at your own risk.

Released under MIT.
Tested with MRI 1.8.7 only.

Installation
============

To use this rubygem:

    $ sudo gem install bing_translator

With bundler:

    gem "bing_translator", "~> 0.0.2"

Usage
=====

    require 'rubygems'
    require 'bing_translator'
    translator = BingTranslator.new 'Your_API_Key'
    spanish = translator.translate 'Hello. This will be translated!', :from => 'en', :to => 'es'

    # without :from for auto language detection
    spanish = translator.translate 'Hello. This will be translated!', :to => 'es'

    locale = translator.detect 'Hello. This will be translated!' # => :en
