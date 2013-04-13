Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '3.1.0'
  s.date        = '2013-04-12'
  s.homepage    = 'https://www.github.com/CodeBlock/bing_translator-gem'
  s.summary     = "Translate using the Bing HTTP API"
  s.description = "Translate strings using the Bing HTTP API. Requires that you have a Client ID and Secret. See README.md for information."
  s.authors     = ["Ricky Elrod"]
  s.email       = 'ricky@elrod.me'
  s.files       = ["lib/bing_translator.rb"]
  s.add_dependency "nokogiri", "~> 1.5.9"
  s.add_dependency "json", "~> 1.7.7"
end
