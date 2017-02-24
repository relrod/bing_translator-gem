Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '4.7.0'
  s.date        = '2017-02-24'
  s.homepage    = 'https://www.github.com/relrod/bing_translator-gem'
  s.summary     = "Translate using the Bing HTTP API"
  s.description = "Translate strings using the Bing HTTP API. Requires that you have a Client ID and Secret. See README.md for information."
  s.authors     = ["Ricky Elrod"]
  s.email       = 'ricky@elrod.me'
  s.files       = ["lib/bing_translator.rb"]
  s.licenses    = ["MIT"]
  s.add_dependency "nokogiri", "~> 1.6.0"
  s.add_dependency "json", "~> 1.8.0"
  s.add_dependency "savon", "~> 2.10.0"
end
