require 'rack/test'
require 'rr'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.mock_with :rr
end
