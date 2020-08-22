require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch if RUBY_VERSION >= '2.5.0'
end

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') < '4.1'
  require 'minitest/unit'

  module Minitest
    Test = MiniTest::Unit::TestCase
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'micro/attributes'

require 'minitest/pride'
require 'minitest/autorun'
