#!/usr/bin/env ruby

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
  WSDL_URI = 'http://api.microsofttranslator.com/V2/soap.svc?wsdl'.freeze
  NAMESPACE_URI = 'http://api.microsofttranslator.com/V2'.freeze
  COGNITIVE_ACCESS_TOKEN_URI = URI.parse('https://api.cognitive.microsoft.com/sts/v1.0/issueToken').freeze

  class Exception < StandardError; end

  def initialize(subscription_key, options = {})
    @skip_ssl_verify = options.fetch(:skip_ssl_verify, false)
    @subscription_key = subscription_key
  end

  def translate(text, params = {})
    raise 'Must provide :to.' if params[:to].nil?

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
    raise 'Must provide :to.' if params[:to].nil?

    # Important notice: param order makes sense in SOAP. Do not reorder or delete!
    params = {
      'texts'       => { 'arr:string' => texts },
      'from'        => params[:from].to_s,
      'to'          => params[:to].to_s,
      'category'    => 'general',
      'contentType' => params[:content_type] || 'text/plain'
    }

    array_wrap(result(:translate_array, params)[:translate_array_response]).map { |r| r[:translated_text] }
  end

  def translate_array2(texts, params = {})
    raise 'Must provide :to.' if params[:to].nil?

    # Important notice: param order makes sense in SOAP. Do not reorder or delete!
    params = {
      'texts'       => { 'arr:string' => texts },
      'from'        => params[:from].to_s,
      'to'          => params[:to].to_s,
      'category'    => 'general',
      'contentType' => params[:content_type] || 'text/plain'
    }

    array_wrap(result(:translate_array2, params)[:translate_array2_response]).map { |r| [r[:translated_text], r[:alignment]] }
   end

  def detect(text)
    params = {
      'text'     => text.to_s,
      'language' => ''
    }

    if lang = result(:detect, params)
      lang.to_sym
    end
  end

  # format:   'audio/wav' [default] or 'audio/mp3'
  # language: valid translator language code
  # options:  'MinSize' [default] or 'MaxQuality'
  def speak(text, params = {})
    raise 'Must provide :language' if params[:language].nil?

    params = {
      'text'     => text.to_s,
      'language' => params[:language].to_s,
      'format'   => params[:format] || 'audio/wav',
      'options'  => params[:options] || 'MinSize'
    }

    uri = URI.parse(result(:speak, params))

    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    end
    results = http.get(uri.to_s, 'Authorization' => "Bearer #{get_access_token['access_token']}")

    if results.response.code.to_i == 200
      results.body
    else
      html = Nokogiri::HTML(results.body)
      raise Exception, html.xpath('//text()').remove.map(&:to_s).join(' ')
    end
  end

  def supported_language_codes
    result(:get_languages_for_translate)[:string]
  end

  def language_names(codes, locale = 'en')
    response = result(:get_language_names, locale: locale, languageCodes: { 'a:string' => codes }) do
      attributes 'xmlns:a' => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
    end

    response[:string]
  end

  private

  # Get a new access token and set it internally as @access_token
  #
  # @return {hash}
  # Returns existing @access_token if we don't need a new token yet,
  # or returns the one just obtained.
  def get_access_token
    headers = {
      'Ocp-Apim-Subscription-Key' => @subscription_key
    }

    http = Net::HTTP.new(COGNITIVE_ACCESS_TOKEN_URI.host, COGNITIVE_ACCESS_TOKEN_URI.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify

    response = http.post(COGNITIVE_ACCESS_TOKEN_URI.path, '', headers)

    @access_token = {
      'access_token' => response.body,
      'expires_at' => Time.now + 480
    }
  end

  # Performs actual request to Bing Translator SOAP API
  def result(action, params = {}, &block)
    soap_client.call(action, message: build_soap_message(params), &block).body[:"#{action}_response"][:"#{action}_result"]
  rescue Savon::SOAPFault => e
    raise Exception, e.message
  end

  # Specify SOAP namespace in tag names (see https://github.com/savonrb/savon/issues/340 )
  #
  # @return [Hash]
  def build_soap_message(params)
    Hash[params.map { |k, v| ["v2:#{k}", v] }]
  end

  # Private: Constructs SOAP client
  #
  # Construct and store new client when called first time.
  # Return stored client while access token is fresh.
  # Construct and store new client when token have been expired.
  def soap_client
    return @client if @client && @access_token && @access_token['expires_at'] &&
                      (Time.now < @access_token['expires_at'])

    @client = Savon.client(
      wsdl: WSDL_URI,
      namespace: NAMESPACE_URI,
      namespace_identifier: :v2,
      namespaces: {
        'xmlns:arr' => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
      },
      headers: { 'Authorization' => "Bearer #{get_access_token['access_token']}" }
    )
  end

  # Private: Array#wrap based on ActiveSupport extension
  def array_wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end
