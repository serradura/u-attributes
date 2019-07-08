unless ENV['DISABLE_SIMPLECOV'] == 'true'
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "micro/attributes"

require "minitest/autorun"
