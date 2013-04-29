Bing Translator
===============

This gem wraps the Microsoft Bing HTTP Translate API.
I am in no way affiliated with Microsoft or Bing.
Use this gem at your own risk.

Released under MIT.
Tested with MRI 2.0.0, 1.9.3 and 1.8.7.

Installation
============

To use this rubygem:

    $ sudo gem install bing_translator

With bundler:

    gem "bing_translator", "~> 3.2.0"

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
translator = BingTranslator.new('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET')
spanish = translator.translate 'Hello. This will be translated!', :from => 'en', :to => 'es'

# without :from for auto language detection
spanish = translator.translate 'Hello. This will be translated!', :to => 'es'

locale = translator.detect 'Hello. This will be translated!' # => :en

# The speak method calls a text-to-speech interface in the supplied language.
# It does not translate the text. Format can be 'audio/mp3' or 'audio/wav'

audio = translator.speak 'Hello. This will be spoken!', :language => :en, :format => 'audio/mp3', :options => 'MaxQuality'
open('file.mp3', 'wb') { |f| f.write audio }

```
