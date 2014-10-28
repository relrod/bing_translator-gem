Bing Translator
===============

[![Gem](https://img.shields.io/gem/v/bing_translator.svg)](https://rubygems.org/gems/bing_translator/) [![Build Status](https://travis-ci.org/relrod/bing_translator-gem.svg?branch=master)](https://travis-ci.org/relrod/bing_translator-gem)

This gem wraps the Microsoft Bing SOAP Translate API.
I am in no way affiliated with Microsoft or Bing.
Use this gem at your own risk.

Released under MIT.
Tested against MRI 2.1.0, 2.0.0 and 1.9.3, and jruby (1.9 mode).

Installation
============

To use this rubygem:

    $ sudo gem install bing_translator

With bundler:

    gem "bing_translator", "~> 4.4.0"

Information
===========

Version 2.0.0+ of bing\_translator uses the new OAuth-based Bing
authentication.

Documentation on the Microsoft Translator API is [here](http://msdn.microsoft.com/en-us/library/ff512419.aspx)

bing\_translator is also smart about requesting the token, and handles this
behind the scenes. It will only request a token if it knows the old one
expired (X seconds from when we requested the last token, where X is given
to us when we make the request. As of this writing, X is consistently 10
minutes).

Getting a Client ID and Secret
==============================

To sign up for the free tier (as of this writing), do the following:

1. Go [here](http://go.microsoft.com/?linkid=9782667)
2. Sign in with valid MSN credentials.
3. On the right side, click 'SIGN UP', under the $0.00 option.
4. Read and accept the terms and conditions and click the big 'SIGN UP'
   button.
5. [Create a new application](https://datamarket.azure.com/developer/applications).
   Fill in a unique client ID, give it a valid name, give it a valid redirect
   URI (not actually used by the Bing Translator API, so it can be anything)
   and hit 'CREATE'.
6. Click on the name of your application to see the info again. You'll need
   the 'Client ID' and 'Client secret' fields.

Usage
=====

```ruby
require 'rubygems'
require 'bing_translator'

# Specify all arguments
translator = BingTranslator.new('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET', false, 'AZURE_ACCOUNT_KEY')

# Or... Specify only required arguments
translator = BingTranslator.new('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET')

spanish = translator.translate 'Hello. This will be translated!', :from => 'en', :to => 'es'

# without :from for auto language detection
spanish = translator.translate 'Hello. This will be translated!', :to => 'es'

locale = translator.detect 'Hello. This will be translated!' # => :en

# The speak method calls a text-to-speech interface in the supplied language.
# It does not translate the text. Format can be 'audio/mp3' or 'audio/wav'

audio = translator.speak 'Hello. This will be spoken!', :language => :en, :format => 'audio/mp3', :options => 'MaxQuality'
open('file.mp3', 'wb') { |f| f.write audio }

# Account balance
translator.balance # => 20000

# get_access_token example
# Useful, e.g., for using bing_translator in a web application frontend
def get_access_token
  begin
    translator = BingTranslator.new('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET', false, 'AZURE_ACCOUNT_KEY')
    token = translator.get_access_token
    token[:status] = 'success'
  rescue Exception => exception
    YourApp.error_logger.error("Bing Translator: \"#{exception.message}\"")
    token = { :status => exception.message }
  end

  token
end

```
