Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '5.2.0'
  s.date        = '2017-12-29'
  s.homepage    = 'https://www.github.com/relrod/bing_translator-gem'
  s.summary     = 'Translate using the Bing HTTP API'
  s.description = 'Translate strings using the Bing HTTP API. Requires that you have a Client ID and Secret. See README.md for information.'
  s.authors     = ['Ricky Elrod']
  s.email       = 'ricky@elrod.me'
  s.files       = ['lib/bing_translator.rb']
  s.licenses    = ['MIT']

  s.add_dependency 'json'
  s.add_dependency 'nokogiri'
  s.add_dependency 'savon'
end
