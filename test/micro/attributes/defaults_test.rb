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

  class ArityOne
    include Micro::Attributes.with(:initialize)

    attribute :str, default: ->(value) { value.to_s }
    attributes :number1, :number2, default: ->(value) { (value || 0).to_i }
  end

  def test_default_receiving_a_lambda_with_1_as_its_arity
    attributes1 = ArityOne.new(str: 1)

    assert_equal('1', attributes1.str)
    assert_equal(0, attributes1.number1)
    assert_equal(0, attributes1.number2)

    attributes2 = ArityOne.new(str: 2, number2: '10')

    assert_equal('2', attributes2.str)
    assert_equal(0, attributes2.number1)
    assert_equal(10, attributes2.number2)
  end

  class ArityTwo
    include Micro::Attributes.with(:initialize)

    attribute :float, default: ->(value, raw_input) { (value || raw_input['integer']).to_f }
    attribute :integer, default: ->(value) { value.to_i }
  end

  def test_default_receiving_a_lambda_with_2_as_its_arity
    attributes1 = ArityTwo.new(integer: '2')

    assert_equal(2.0, attributes1.float)
    assert_equal(2, attributes1.integer)

    attributes2 = ArityTwo.new(float: 1.5, integer: '3')

    assert_equal(1.5, attributes2.float)
    assert_equal(3, attributes2.integer)
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
