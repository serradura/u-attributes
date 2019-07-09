require "test_helper"

class Micro::AttributesVersionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Micro::Attributes::VERSION
  end
end
