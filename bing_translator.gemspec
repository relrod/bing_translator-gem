Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '1.1.0'
  s.date        = '2012-02-21'
  s.homepage    = 'https://www.github.com/CodeBlock/bing_translator-gem'
  s.summary     = "Translate using the Bing HTTP API"
  s.description = "Translate strings using the Bing HTTP API. Requires that you have an API key. See http://www.microsoft.com/web/post/using-the-free-bing-translation-apis"
  s.authors     = ["Ricky Elrod"]
  s.email       = 'ricky@elrod.me'
  s.files       = ["lib/bing_translator.rb"]
  s.add_dependency "nokogiri", "~> 1.5.0"
end
