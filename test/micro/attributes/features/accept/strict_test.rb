require 'test_helper'

class Micro::Attributes::Features::AcceptStrictTest < Minitest::Test
  class CalcWithIndifferentAccess
    include Micro::Attributes.with(accept: :strict)

    attribute :a, accept: Numeric
    attribute :b, accept: Numeric
    attribute :operator, reject: Numeric

    def initialize(data)
      self.attributes = data
    end

    def call
      return if attributes_errors?

      return a + b if String(operator) == '+'
    end
  end

  def test_the_accept_with_kind_of_and_keys_as_symbol
    calc1 = CalcWithIndifferentAccess.new(a: 1, b: 2.0, operator: '+')

    assert_equal(3.0, calc1.call)
    assert_equal({}, calc1.attributes_errors)
    assert_equal([], calc1.rejected_attributes)
    assert_equal(['a', 'b', 'operator'], calc1.accepted_attributes)

    # --

    refute_predicate(calc1, :attributes_errors?)
    refute_predicate(calc1, :rejected_attributes?)
    assert_predicate(calc1, :accepted_attributes?)

    # -- --

    err = assert_raises(ArgumentError) { CalcWithIndifferentAccess.new(a: '1', b: 2, operator: 0) }
    err_message =
      "One or more attributes were rejected. Errors:\n"\
      "* \"a\" expected to be a kind of Numeric\n"   \
      "* \"operator\" expected to not be a kind of Numeric"

    assert_equal(err_message, err.message)
  end

  class CalcWithKeysAsSymbol
    include Micro::Attributes.with(:initialize, :keys_as_symbol, accept: :strict)

    attribute :a, accept: Numeric
    attribute :b, accept: Numeric
    attribute :operator, reject: Numeric

    def call
      return if attributes_errors?

      return a + b if String(operator) == '+'
    end
  end

  def test_the_accept_with_kind_of_and_indifferent_access
    calc1 = CalcWithKeysAsSymbol.new(a: 1, b: 2.0, operator: '+')

    assert_equal(3.0, calc1.call)
    assert_equal({}, calc1.attributes_errors)
    assert_equal([], calc1.rejected_attributes)
    assert_equal([:a, :b, :operator], calc1.accepted_attributes)

    # --

    refute_predicate(calc1, :attributes_errors?)
    refute_predicate(calc1, :rejected_attributes?)
    assert_predicate(calc1, :accepted_attributes?)

    # -- --

    err = assert_raises(ArgumentError) { CalcWithKeysAsSymbol.new(a: '1', b: 2, operator: 0) }
    err_message =
      "One or more attributes were rejected. Errors:\n"\
      "* :a expected to be a kind of Numeric\n"   \
      "* :operator expected to not be a kind of Numeric"

    assert_equal(err_message, err.message)
  end
end
