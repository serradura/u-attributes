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

  def test_defaults_defined_via_the_attribute_methods
    assert_equal(2, Add.new({}).call)
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

  def test_defaults_defined_via_the_attributes_method
    assert_equal(4, Sum.new({}).call)
    assert_equal(3, Sum.new(a: 1).call)
    assert_equal(5, Sum.new(b: 3).call)
    assert_equal(5, Sum.new(a: 2, b: 3).call)
  end

  class ArityZero
    include Micro::Attributes.with(:initialize)

    attribute :a, default: -> { Time.now }
    attributes :b, :c, default: -> { Time.now + 1 }
  end

  def test_default_receiving_a_lambda_with_0_as_its_arity
    attributes = ArityZero.new({})

    assert attributes.b > attributes.a
    assert attributes.c > attributes.a
    assert attributes.b != attributes.c
    assert attributes.b.strftime('%H:%M:%S') == attributes.c.strftime('%H:%M:%S')
  end

  class ProcWithToProc
    include Micro::Attributes.with(:initialize)

    attribute :str, default: proc(&:to_s)
  end

  def test_default_receiving_to_proc
    assert_equal('', ProcWithToProc.new(str: nil).str)
    assert_equal('1', ProcWithToProc.new(str: 1).str)
    assert_equal('a', ProcWithToProc.new(str: :a).str)
  end
end
