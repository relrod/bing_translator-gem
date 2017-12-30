Bing Translator
===============

[![Gem](https://img.shields.io/gem/v/bing_translator.svg)](https://rubygems.org/gems/bing_translator/) [![Build Status](https://travis-ci.org/relrod/bing_translator-gem.svg?branch=master)](https://travis-ci.org/relrod/bing_translator-gem)

This gem wraps the Microsoft Cognitive Services Translator API.

Installation
============

To use this rubygem:

    $ sudo gem install bing_translator

With bundler:

    gem "bing_translator", "~> 5.2.0"

Information
===========

Documentation on the Microsoft Translator API is [here](https://www.microsoft.com/cognitive-services/en-us/translator-api)

bing\_translator is also smart about requesting the token, and handles this
behind the scenes. It will only request a token if it knows the old one
expired (X seconds from when we requested the last token, where X is given
to us when we make the request. As of this writing, X is consistently 8
minutes).

Getting a free Azure account  
==============================

To be able to use the API freely, do the following:

1. Go [here](https://azure.microsoft.com/en-us/free/)
2. Sign in with valid Live credentials.
3. Add the resource 'Cognitive Services APIs'
4. In 'RESOURCE MANAGEMENT > Keys' pick either 'KEY 1' or 'KEY 2'

Usage
=====

```ruby
require 'rubygems'
require 'bing_translator'

translator = BingTranslator.new('COGNITIVE_SUBSCRIPTION_KEY')

# Translation

spanish = translator.translate('Hello. This will be translated!', :from => 'en', :to => 'es')
spanish = translator.translate('Hello. This will be translated!', :to => 'es')

# Translation of multiple strings

result = translator.translate_array(['Hello. This will be translated!', 'This will be translated too!'], :from => :en, :to => :fr)

# Translation of multiple strings, with word alignment information

result = translator.translate_array(['Hello. This will be translated!', 'This will be translated too!'], :from => :en, :to => :fr)

# Language Detection

locale = translator.detect('Hello. This will be translated!') # => :en

# The speak method calls a text-to-speech interface in the supplied language.
# It does not translate the text. Format can be 'audio/mp3' or 'audio/wav'

audio = translator.speak('Hello. This will be spoken!', :language => :en, :format => 'audio/mp3', :options => 'MaxQuality')
File.write('file.mp3', audio, mode: 'wb')
```
