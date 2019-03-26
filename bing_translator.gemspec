Gem::Specification.new do |s|
  s.name        = 'bing_translator'
  s.version     = '6.0.0.beta.2'
  s.date        = '2019-03-25'
  s.homepage    = 'https://www.github.com/relrod/bing_translator-gem'
  s.summary     = 'Translate using the Bing HTTP API'
  s.description = 'Translate strings using the Bing HTTP API. Requires that you have a Client ID and Secret. See README.md for information.'
  s.authors     = ['Ricky Elrod']
  s.email       = 'ricky@elrod.me'
  s.files       = ['lib/bing_translator.rb']
  s.licenses    = ['MIT']

  s.add_dependency 'json'
end
