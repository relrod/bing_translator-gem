Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '5.1.0'
  s.date        = '2017-12-18'
  s.homepage    = 'https://www.github.com/relrod/bing_translator-gem'
  s.summary     = "Translate using the Bing HTTP API"
  s.description = "Translate strings using the Bing HTTP API. Requires that you have a Client ID and Secret. See README.md for information."
  s.authors     = ["Ricky Elrod"]
  s.email       = 'ricky@elrod.me'
  s.files       = ["lib/bing_translator.rb"]
  s.licenses    = ["MIT"]
  s.add_dependency "nokogiri", "~> 1.8.1"
  s.add_dependency "json", "~> 1.8.0"
  s.add_dependency "savon", "~> 2.10.0"

  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rspec-html-matchers", ">= 0.9.1", "< 0.10.0"
  s.add_development_dependency "dotenv"
end
