#!/usr/bin/env ruby
# encoding: utf-8
# (c) 2011-present. Ricky Elrod <ricky@elrod.me>
# Released under the MIT license.
require 'rubygems'
require 'cgi'
require 'uri'
require 'net/http'
require 'nokogiri'

class BingTranslator
  TRANSLATE_URI = 'http://api.microsofttranslator.com/V2/Http.svc/Translate'
  DETECT_URI = 'http://api.microsofttranslator.com/V2/Http.svc/Detect'
  
  def initialize(api_key)
    @api_key = api_key
    @translate_uri = URI.parse TRANSLATE_URI
    @detect_uri = URI.parse DETECT_URI
  end
  
  def translate(text, params = {})
    raise "Must provide :to." if params[:to].nil?

    from = CGI.escape params[:from].to_s
    params = {
      'to' => CGI.escape(params[:to].to_s),
      'text' => CGI.escape(text.to_s),
      'appId' => @api_key,
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
      'appId' => @api_key,
      'category' => 'general',
      'contentType' => 'text/plain'
    }
    result = result @detect_uri, params

    Nokogiri.parse(result.body).xpath("//xmlns:string")[0].content.to_sym
  end

private
  def prepare_param_string(params)
    params.map {|key, value| "#{key}=#{value}"}.join '&'
  end

  def result(uri, params)
    result = Net::HTTP.new(uri.host, uri.port).get("#{uri.path}?#{prepare_param_string(params)}")
  end
end
