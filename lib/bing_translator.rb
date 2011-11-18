#!/usr/bin/env ruby
require 'rubygems'
require 'cgi'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'pp'

class BingTranslator
  TRANSLATE_URI = 'http://api.microsofttranslator.com/V2/Http.svc/Translate'
  
  def initialize(params = {})
    if params[:api_key].nil?
      raise "Must pass :api_key when initializing BingTranslator"
    end
    @api_key = params[:api_key]
  end
  
  def translate(params = {})
    if params[:to].nil? or params[:from].nil? or params[:text].nil?
      raise "Must provide :to, :from, and :text."
    else
      to = CGI.escape params[:to]
      from = CGI.escape params[:from]
      text = CGI.escape params[:text]
      uri = URI.parse(TRANSLATE_URI)
      params = {
        'to' => to,
        'from' => from,
        'text' => text,
        'appId' => @api_key,
        'category' => 'general',
        'contentType' => 'text/plain'
      }
      params_s = params.map {|key, value| "#{key}=#{value}"}.join '&'
      result = Net::HTTP.new(uri.host, uri.port)
      result = result.get("#{uri.path}?#{params_s}")
      noko = Nokogiri.parse(result.body)
      noko.xpath("//xmlns:string")[0].content
    end
  end
end
