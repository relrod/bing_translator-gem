#!/usr/bin/env ruby
# encoding: utf-8
# (c) 2011-present. Ricky Elrod <ricky@elrod.me>
# Released under the MIT license.
require 'rubygems'
require 'cgi'
require 'uri'
require 'net/http'
require 'net/https'
require 'nokogiri'
require 'json'

class BingTranslator
  TRANSLATE_URI = 'http://api.microsofttranslator.com/V2/Http.svc/Translate'
  DETECT_URI = 'http://api.microsofttranslator.com/V2/Http.svc/Detect'
  LANG_CODE_LIST_URI = 'http://api.microsofttranslator.com/V2/Http.svc/GetLanguagesForTranslate'
  ACCESS_TOKEN_URI = 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13'
  SPEAK_URI = 'http://api.microsofttranslator.com/v2/Http.svc/Speak'

  def initialize(client_id, client_secret, skip_ssl_verify = false)
    @client_id = client_id
    @client_secret = client_secret
    @translate_uri = URI.parse TRANSLATE_URI
    @detect_uri = URI.parse DETECT_URI
    @list_codes_uri = URI.parse LANG_CODE_LIST_URI
    @access_token_uri = URI.parse ACCESS_TOKEN_URI
    @speak_uri = URI.parse SPEAK_URI
    @skip_ssl_verify = skip_ssl_verify ? true : false
  end

  def translate(text, params = {})
    raise "Must provide :to." if params[:to].nil?

    from = CGI.escape params[:from].to_s
    params = {
      'to' => CGI.escape(params[:to].to_s),
      'text' => CGI.escape(text.to_s),
      'category' => 'general',
      'contentType' => 'text/plain'
    }
    params[:from] = from unless from.empty?
    result = result @translate_uri, params

    Nokogiri.parse(result.body).xpath("//xmlns:string")[0].content
  end

  def detect(text)
    params = {
      'text' => CGI.escape(text.to_s),
      'category' => 'general',
      'contentType' => 'text/plain'
    }
    result = result @detect_uri, params

    Nokogiri.parse(result.body).xpath("//xmlns:string")[0].content.to_sym
  end

  # format:   'audio/wav' [default] or 'audio/mp3'
  # language: valid translator language code
  # options:  'MinSize' [default] or 'MaxQuality'
  def speak(text, params = {})
    raise "Must provide :language" if params[:language].nil?

    params = {
      'format' => CGI.escape(params[:format].to_s),
      'text' => CGI.escape(text.to_s),
      'language' => params[:language].to_s
    }

    result = result(@speak_uri, params, { "Content-Type" => params[:format].to_s })

    result.body
  end

  def supported_language_codes
    result = result @list_codes_uri
    Nokogiri.parse(result.body).xpath("//xmlns:string").map(&:content)
  end


private
  def prepare_param_string(params)
    params.map { |key, value| "#{key}=#{value}" }.join '&'
  end

  def result(uri, params={}, headers={})
    get_access_token
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    end
                        
    results = http.get(
      "#{uri.path}?#{prepare_param_string(params)}",
        { 
          'Authorization' => "Bearer #{@access_token['access_token']}" 
        })
  end

  # Private: Get a new access token
  #
  # Microsoft changed up how you get access to the Translate API.
  # This gets a new token if it's required. We call this internally
  # before any request we make to the Translate API.
  #
  # Returns nothing if we don't need a new token yet, or
  #   a Hash of information relating to the token if we obtained a new one.
  #   Also sets @access_token internally.
  def get_access_token
    return @access_token if @access_token and
      Time.now < @access_token['expires_at']

    params = {
      'client_id' => CGI.escape(@client_id),
      'client_secret' => CGI.escape(@client_secret),
      'scope' => CGI.escape('http://api.microsofttranslator.com'),
      'grant_type' => 'client_credentials'
    }

    http = Net::HTTP.new(@access_token_uri.host, @access_token_uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    
    response = http.post(@access_token_uri.path, prepare_param_string(params))
    @access_token = JSON.parse(response.body)
    raise "Authentication error: #{@access_token['error']}" if @access_token["error"]
    @access_token['expires_at'] = Time.now + @access_token['expires_in'].to_i
    @access_token
  end
end
