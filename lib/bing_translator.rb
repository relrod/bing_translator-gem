#!/usr/bin/env ruby

# (c) 2011-present. Ricky Elrod <ricky@elrod.me>
# Released under the MIT license.
require 'rubygems'
require 'cgi'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'

class BingTranslator
  API_HOST = 'https://api.cognitive.microsofttranslator.com'.freeze
  COGNITIVE_ACCESS_TOKEN_URI = URI.parse('https://api.cognitive.microsoft.com/sts/v1.0/issueToken').freeze

  class Exception < StandardError; end

  def initialize(subscription_key, options = {})
    @skip_ssl_verify = options.fetch(:skip_ssl_verify, false)
    @subscription_key = subscription_key
  end

  def translate(text, from: nil, to:, html: false)
    raise 'Must provide :to.' if to.nil?

    params = { to: to, textType: html ? 'html' : 'plain' }
    params[:from] = from if from
    data = [{ 'Text' => text }].to_json

    response_json = api_call('/translate', params, data)
    translations = Array(response_json.first['translations'])
    target_translation = translations.find { |result| result['to'] == to.to_s }
    target_translation['text'] if target_translation
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
    data = [{ 'Text' => text }].to_json

    response_json = api_call('/detect', {}, data)
    best_detection = response_json.sort_by { |detection| -detection['score'] }.first
    best_detection['language'].to_sym
  end

  def speak(text, params = {})
    raise 'Not supported since 3.0.0'
  end

  def supported_language_codes
    response_json = get_request('/languages', { scope: 'translation' })
    response_json['translation'].keys
  end

  def language_names(codes, locale = 'en')
    response_json = get_request('/languages', { scope: 'translation' }, { 'Accept-Language' => locale})
    codes.map do |code|
      response = response_json['translation'][code.to_s]
      response['name'] unless response.nil?
    end
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
    if response.code != '200'
      raise Exception.new('Invalid credentials')
    else
      @access_token = {
        'access_token' => response.body,
        'expires_at' => Time.now + 480
      }
    end
  end

  def get_request(path, params, headers = {})
    encoded_params = URI.encode_www_form(params.merge('api-version' => '3.0'))
    uri = URI.parse("#{API_HOST}#{path}")
    uri.query = encoded_params
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    headers = headers.merge('Content-Type' => 'application/json')
    request = Net::HTTP::Get.new(uri.request_uri, headers)

    JSON.parse(http.request(request).body)
  end

  def api_call(path, params, data)
    if @access_token.nil? || @access_token['expires_at'].nil? || 
      Time.now < @access_token['expires_at']
      get_access_token
    end

    encoded_params = URI.encode_www_form(params.merge('api-version' => '3.0'))
    uri = URI.parse("#{API_HOST}#{path}")
    uri.query = encoded_params
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@access_token['access_token']}"
    }
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = data

    JSON.parse(http.request(request).body)
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
