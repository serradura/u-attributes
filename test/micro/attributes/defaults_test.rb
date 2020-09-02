require 'test_helper'

class Micro::Attributes::DefaultsTest < Minitest::Test
  class Add
    include Micro::Attributes.with(:initialize)

    attribute :a, default: 1
    attribute :b, default: 1

    def call
      a + b
    end
  end

  def test_defaults_defined_via_the_attribute_method
    assert_equal(1, Add.new({}).call)
    assert_equal(3, Add.new(a: 2).call)
    assert_equal(4, Add.new(b: 3).call)
    assert_equal(5, Add.new(a: 2, b: 3).call)
  end

  class Sum
    include Micro::Attributes.with(:initialize)

    attributes :a, :b, default: 2

    def call
      a + b
    end
  end

  def test_defaults_defined_via_the_attribute_method
    assert_equal(4, Sum.new({}).call)
    assert_equal(3, Sum.new(a: 1).call)
    assert_equal(5, Sum.new(b: 3).call)
    assert_equal(5, Sum.new(a: 2, b: 3).call)
  end
end
