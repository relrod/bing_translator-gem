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
require 'savon'

class BingTranslator
  WSDL_URI = 'http://api.microsofttranslator.com/V2/soap.svc?wsdl'
  NAMESPACE_URI = 'http://api.microsofttranslator.com/V2'
  ACCESS_TOKEN_URI = 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13'
  DATASETS_URI = "https://api.datamarket.azure.com/Services/My/Datasets?$format=json"

  class Exception < StandardError; end
  class AuthenticationException < StandardError; end

  def initialize(client_id, client_secret, skip_ssl_verify = false, account_key = nil)
    @client_id = client_id
    @client_secret = client_secret
    @account_key = account_key
    @skip_ssl_verify = skip_ssl_verify

    @access_token_uri = URI.parse ACCESS_TOKEN_URI
    @datasets_uri = URI.parse DATASETS_URI
  end

  def translate(text, params = {})
    raise "Must provide :to." if params[:to].nil?

    # Important notice: param order makes sense in SOAP. Do not reorder or delete!
    params = {
      'text'        => text.to_s,
      'from'        => params[:from].to_s,
      'to'          => params[:to].to_s,
      'category'    => 'general',
      'contentType' => params[:content_type] || 'text/plain'
    }

    result(:translate, params)
  end

  def translate_array(texts, params = {})
    raise "Must provide :to." if params[:to].nil?

    # Important notice: param order makes sense in SOAP. Do not reorder or delete!
    params = {
      'texts'       => { 'arr:string' => texts },
      'from'        => params[:from].to_s,
      'to'          => params[:to].to_s,
      'category'    => 'general',
      'contentType' => params[:content_type] || 'text/plain'
    }

    result(:translate_array, params)[:translate_array_response].map{|r| r[:translated_text]}
  end

  def detect(text)
    params = {
      'text'     => text.to_s,
      'language' => '',
    }

    result(:detect, params).to_sym
  end

  # format:   'audio/wav' [default] or 'audio/mp3'
  # language: valid translator language code
  # options:  'MinSize' [default] or 'MaxQuality'
  def speak(text, params = {})
    raise "Must provide :language" if params[:language].nil?

    params = {
      'text'     => text.to_s,
      'language' => params[:language].to_s,
      'format'   => params[:format] || 'audio/wav',
      'options'  => params[:options] || 'MinSize',
    }

    uri = URI.parse(result(:speak, params))

    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    end
    results = http.get(uri.to_s, {'Authorization' => "Bearer #{get_access_token['access_token']}"})

    if results.response.code.to_i == 200
      results.body
    else
      html = Nokogiri::HTML(results.body)
      raise Exception, html.xpath("//text()").remove.map(&:to_s).join(' ')
    end
  end

  def supported_language_codes
    result(:get_languages_for_translate)[:string]
  end

  def language_names(codes, locale = 'en')
    response = result(:get_language_names, locale: locale, languageCodes: {'a:string' => codes}) do
      attributes 'xmlns:a' => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
    end

    response[:string]
  end

  def balance
    datasets["d"]["results"].each do |result|
      return result["ResourceBalance"] if result["ProviderName"] == "Microsoft Translator"
    end
  end

  # Get a new access token and set it internally as @access_token
  #
  # Microsoft changed up how you get access to the Translate API.
  # This gets a new token if it's required. We call this internally
  # before any request we make to the Translate API.
  #
  # @return {hash}
  # Returns existing @access_token if we don't need a new token yet,
  # or returns the one just obtained.
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
    raise AuthenticationException, @access_token['error'] if @access_token["error"]
    @access_token['expires_at'] = Time.now + @access_token['expires_in'].to_i
    @access_token
  end

private
  def datasets
    raise AuthenticationException, "Must provide account key" if @account_key.nil?

    http = Net::HTTP.new(@datasets_uri.host, @datasets_uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(@datasets_uri.request_uri)
    request.basic_auth("", @account_key)
    response = http.request(request)

    JSON.parse response.body
  end

  def prepare_param_string(params)
    params.map { |key, value| "#{key}=#{value}" }.join '&'
  end

  # Public: performs actual request to Bing Translator SOAP API
  def result(action, params = {}, &block)
    # Specify SOAP namespace in tag names (see https://github.com/savonrb/savon/issues/340 )
    params = Hash[params.map{|k,v| ["v2:#{k}", v]}]
    begin
      soap_client.call(action, message: params, &block).body[:"#{action}_response"][:"#{action}_result"]
    rescue AuthenticationException
      raise
    rescue StandardError => e
      # Keep old behaviour: raise only internal Exception class
      raise Exception, e.message
    end
  end

  # Private: Constructs SOAP client
  #
  # Construct and store new client when called first time.
  # Return stored client while access token is fresh.
  # Construct and store new client when token have been expired.
  def soap_client
    return @client if @client and @access_token and
      Time.now < @access_token['expires_at']

    @client = Savon.client(
      wsdl: WSDL_URI,
      namespace: NAMESPACE_URI,
      namespace_identifier: :v2,
      namespaces: {
        'xmlns:arr' =>  'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
      },
      headers: {'Authorization' => "Bearer #{get_access_token['access_token']}"},
    )
  end
end
