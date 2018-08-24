require 'dotenv'
Dotenv.load

require File.join(File.dirname(__FILE__), '..', 'lib', 'bing_translator')

require 'rspec-html-matchers'

RSpec.configure do |config|
  config.expect_with :rspec
end
