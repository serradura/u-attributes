require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'u-case'

if defined?(ActiveModel)
  Micro::Case.config do |config|
    config.enable_activemodel_validation = true
  end
end

require 'micro/attributes'

require 'minitest/pride'
require 'minitest/autorun'
