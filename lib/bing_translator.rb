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
  class Exception < StandardError; end

  class ApiClient
    API_HOST = 'https://api.cognitive.microsofttranslator.com'.freeze
    COGNITIVE_ACCESS_TOKEN_URI =
      URI.parse('https://api.cognitive.microsoft.com/sts/v1.0/issueToken').freeze

    def initialize(subscription_key, skip_ssl_verify)
      @subscription_key = subscription_key
      @skip_ssl_verify = skip_ssl_verify
    end

    def get(path, params: {}, headers: {}, authorization: false)
      uri = request_uri(path, params)
      request = Net::HTTP::Get.new(uri.request_uri, default_headers(authorization).merge(headers))

      json_response(uri, request)
    end

    def post(path, params: {}, headers: {}, data: {}, authorization: true)
      uri = request_uri(path, params)

      request = Net::HTTP::Post.new(uri.request_uri, default_headers(authorization).merge(headers))
      request.body = data

      json_response(uri, request)
    end

    private

    def default_headers(authorization = true)
      headers = { 'Content-Type' => 'application/json' }
      headers['Authorization'] = "Bearer #{access_token}" if authorization
      headers
    end

    def json_response(uri, request)
      http = http_client(uri)

      response = http.request(request)

      raise Exception.new("Unsuccessful API call: Code: #{response.code}") unless response.code == '200'
      JSON.parse(response.body)
    end

    def http_client(uri)
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
      http
    end

    def request_uri(path, params)
      encoded_params = URI.encode_www_form(params.merge('api-version' => '3.0'))
      uri = URI.parse("#{API_HOST}#{path}")
      uri.query = encoded_params
      uri
    end

    def access_token
      if @access_token.nil? || Time.now < @access_token_expiration_time
        @access_token = request_new_access_token
      end
      @access_token
    end

    def request_new_access_token
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
        @access_token_expiration_time = Time.now + 480
        response.body
      end
    end
  end

  def initialize(subscription_key, options = {})
    skip_ssl_verify = options.fetch(:skip_ssl_verify, false)
    @api_client = ApiClient.new(subscription_key, skip_ssl_verify)
  end

  def translate(text, from: nil, to:, html: false)
    raise 'Must provide :to.' if to.nil?

    params = { to: to, textType: html ? 'html' : 'plain' }
    params[:from] = from if from
    data = [{ 'Text' => text }].to_json

    response_json = api_client.post('/translate', params: params, data: data)
    translations = Array(response_json.first['translations'])
    target_translation = translations.find { |result| result['to'] == to.to_s }
    target_translation['text'] if target_translation
  end

  def translate_array(texts, params = {}, include_alignment = false)
    raise 'Must provide :to.' if params[:to].nil?

    params = {
      'from'             => params[:from].to_s,
      'to'               => params[:to].to_s
    }
    data = texts.map { |text| { 'Text' => text } }.to_json
    response_json = api_client.post('/translate', params: params, data: data)
    response_json.map do |translation|
      target_translation = translation['translations'].find { |result| result['to'] == params['to'].to_s }
      target_translation['text'] if target_translation
    end
  end

  def translate_array2(texts, params = {})
    raise 'Must provide :to.' if params[:to].nil?

    params = {
      'includeAlignment' => true,
      'from'             => params[:from].to_s,
      'to'               => params[:to].to_s
    }
    data = texts.map { |text| { 'Text' => text } }.to_json
    response_json = api_client.post('/translate', params: params, data: data)
    response_json.map do |translation|
      target_translation = translation['translations'].find { |result| result['to'] == params['to'].to_s }
      [target_translation['text'], target_translation['alignment']['proj']] if target_translation
    end
  end

  def detect(text)
    data = [{ 'Text' => text }].to_json

    response_json = api_client.post('/detect', data: data)
    best_detection = response_json.sort_by { |detection| -detection['score'] }.first
    best_detection['language'].to_sym
  end

  def speak(text, params = {})
    raise 'Not supported since 3.0.0'
  end

  def supported_language_codes
    response_json = api_client.get('/languages', params: { scope: 'translation' }, authorization: false)
    response_json['translation'].keys
  end

  def language_names(codes, locale = 'en')
    response_json = api_client.get('/languages', params: { scope: 'translation' }, headers: { 'Accept-Language' => locale }, authorization: false)
    codes.map do |code|
      response = response_json['translation'][code.to_s]
      response['name'] unless response.nil?
    end
  end

  private

  attr_reader :api_client
end
