# Pre-require stdlib that older Rails (6.x/7.0) expects but no longer
# auto-loads on Ruby 3+. Avoids "uninitialized constant Logger" /
# "uninitialized constant StringIO" failures when ActiveModel is loaded.
require 'logger'
require 'stringio'

# Ruby 3.1+ enriches NameError#message with a source-code snippet via
# error_highlight. Tests assert on the raw message text, so disable the
# annotation when available.
begin
  require 'error_highlight'
  ErrorHighlight.formatter = Class.new { def message_for(_); ''; end }.new
rescue LoadError
end

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'u-case'

require 'micro/attributes'

require 'minitest/pride'
require 'minitest/autorun'
