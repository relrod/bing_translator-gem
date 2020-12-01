Bing Translator
===============

[![Gem](https://img.shields.io/gem/v/bing_translator.svg)](https://rubygems.org/gems/bing_translator/) ![bing_translator tests](https://github.com/relrod/bing_translator-gem/workflows/bing_translator%20tests/badge.svg)

This gem wraps the Microsoft Cognitive Services Translator API.

Installation
============

To use this rubygem:

    $ sudo gem install bing_translator

With bundler:

    gem "bing_translator", "~> 6.1.0"

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

# HTML Translations
spanish_html = translator.translate('<b>Hello</b>', to: 'es', textType: 'html')

# Translation of multiple strings

result = translator.translate_array(['Hello. This will be translated!', 'This will be translated too!'], :from => :en, :to => :fr)

# Translation of multiple strings, with word alignment information

result = translator.translate_array2(['Hello. This will be translated!', 'This will be translated too!'], :from => :en, :to => :fr)

# Language Detection

locale = translator.detect('Hello. This will be translated!') # => :en
```

Migration to API V3
===================
Since version 6.0.0, this gem uses Microsoft Cognitive Translation Services in version 3.

Microsoft is dropping the support of Cognitive Translation Services Version 2 in April 2019. If you want to continue using this gem, migrate to 6.0.0.

I did my best to keep the backward compatibility with the previous gem version, but there are some breaking changes:
* I dropped the support for the `#speak` method. If you need it, please create a GitHub issue, and I'll consider supporting it too.
* I changed the interface for HTML translations. See the documentation above.
* In the API v3, Microsoft does not allow translation of texts longer than 5000 characters.
