if RUBY_VERSION >= '2.4.0'
  require 'simplecov'

  SimpleCov.start do
    add_filter '/test/'

    enable_coverage :branch if RUBY_VERSION >= '2.5.0'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'u-case'

if activemodel_version = ENV['ACTIVEMODEL_VERSION']
  if activemodel_version < '4.1'
    require 'minitest/unit'

    module Minitest
      Test = MiniTest::Unit::TestCase
    end
  end

  Micro::Case.config do |config|
    config.enable_activemodel_validation = true
  end
end

require 'micro/attributes'

require 'minitest/pride'
require 'minitest/autorun'
