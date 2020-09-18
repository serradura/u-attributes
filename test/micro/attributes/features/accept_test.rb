require 'test_helper'

class Micro::Attributes::Features::AcceptTest < Minitest::Test
  class CalcWithIndifferentAccess
    include Micro::Attributes.with(:accept)

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

  def test_the_accept_with_kind_of_and_indifferent_access
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

    calc2 = CalcWithIndifferentAccess.new(a: '1', b: 2, operator: 0)
    calc3 = CalcWithIndifferentAccess.new(a: '1', b: '2.0', operator: '+')

    assert_nil(calc2.call)
    assert_nil(calc3.call)

    assert_equal({
      'a' => 'expected to be a kind of Numeric',
      'operator' => 'expected to not be a kind of Numeric'
    }, calc2.attributes_errors)

    assert_equal({
      'a' => 'expected to be a kind of Numeric',
      'b' => 'expected to be a kind of Numeric'
    }, calc3.attributes_errors)

    assert_equal(['a', 'operator'], calc2.rejected_attributes)
    assert_equal(['a', 'b'], calc3.rejected_attributes)

    assert_equal(['b'], calc2.accepted_attributes)
    assert_equal(['operator'], calc3.accepted_attributes)

    # --

    assert_predicate(calc2, :attributes_errors?)
    assert_predicate(calc3, :attributes_errors?)

    assert_predicate(calc2, :rejected_attributes?)
    assert_predicate(calc3, :rejected_attributes?)

    refute_predicate(calc2, :accepted_attributes?)
    refute_predicate(calc3, :accepted_attributes?)
  end

  class CalcKeysAsSymbol
    include Micro::Attributes.with(:accept, :keys_as_symbol)

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
    calc1 = CalcKeysAsSymbol.new(a: 1, b: 2.0, operator: '+')

    assert_equal(3.0, calc1.call)

    assert_equal({}, calc1.attributes_errors)

    assert_equal([], calc1.rejected_attributes)

    assert_equal([:a, :b, :operator], calc1.accepted_attributes)

    # --

    refute_predicate(calc1, :attributes_errors?)

    refute_predicate(calc1, :rejected_attributes?)

    assert_predicate(calc1, :accepted_attributes?)

    # -- --

    calc2 = CalcKeysAsSymbol.new(a: '1', b: 2, operator: 0)
    calc3 = CalcKeysAsSymbol.new(a: '1', b: '2.0', operator: '+')

    assert_nil(calc2.call)
    assert_nil(calc3.call)

    assert_equal({
      a: 'expected to be a kind of Numeric',
      operator: 'expected to not be a kind of Numeric'
    }, calc2.attributes_errors)

    assert_equal({
      a: 'expected to be a kind of Numeric',
      b: 'expected to be a kind of Numeric'
    }, calc3.attributes_errors)

    assert_equal([:a, :operator], calc2.rejected_attributes)
    assert_equal([:a, :b], calc3.rejected_attributes)

    assert_equal([:b], calc2.accepted_attributes)
    assert_equal([:operator], calc3.accepted_attributes)

    # --

    assert_predicate(calc2, :attributes_errors?)
    assert_predicate(calc3, :attributes_errors?)

    assert_predicate(calc2, :rejected_attributes?)
    assert_predicate(calc3, :rejected_attributes?)

    refute_predicate(calc2, :accepted_attributes?)
    refute_predicate(calc3, :accepted_attributes?)
  end

  class PersonWithIndifferentAccess
    include Micro::Attributes.with(:accept, :initialize)

    attribute :name, reject: :empty?
    attribute :age, accept: :integer?
  end

  def test_the_accept_with_to_proc_and_indifferent_access
    person1 = PersonWithIndifferentAccess.new(name: 'Rodrigo', age: 33)

    assert_equal({}, person1.attributes_errors)

    assert_equal([], person1.rejected_attributes)

    assert_equal(['name', 'age'], person1.accepted_attributes)

    # --

    refute_predicate(person1, :attributes_errors?)

    refute_predicate(person1, :rejected_attributes?)

    assert_predicate(person1, :accepted_attributes?)

    # -- --

    person2 = PersonWithIndifferentAccess.new(name: '', age: 33.0)

    assert_equal({
      'name' => 'expected to not be empty?',
      'age' => 'expected to be integer?'
    }, person2.attributes_errors)

    assert_equal(['name', 'age'], person2.rejected_attributes)

    assert_equal([], person2.accepted_attributes)

    # --

    assert_predicate(person2, :attributes_errors?)

    assert_predicate(person2, :rejected_attributes?)

    refute_predicate(person2, :accepted_attributes?)
  end

  class PersonKeysAsSymbol
    include Micro::Attributes.with(:accept, :initialize, :keys_as_symbol)

    attribute :name, reject: :empty?
    attribute :age, accept: :integer?
  end

  def test_the_accept_with_to_proc_and_keys_as_symbol
    person1 = PersonKeysAsSymbol.new(name: 'Rodrigo', age: 33)

    assert_equal({}, person1.attributes_errors)

    assert_equal([], person1.rejected_attributes)

    assert_equal([:name, :age], person1.accepted_attributes)

    # --

    refute_predicate(person1, :attributes_errors?)

    refute_predicate(person1, :rejected_attributes?)

    assert_predicate(person1, :accepted_attributes?)

    # -- --

    person2 = PersonKeysAsSymbol.new(name: '', age: 33.0)

    assert_equal({
      name: 'expected to not be empty?',
      age: 'expected to be integer?'
    }, person2.attributes_errors)

    assert_equal([:name, :age], person2.rejected_attributes)

    assert_equal([], person2.accepted_attributes)

    # --

    assert_predicate(person2, :attributes_errors?)

    assert_predicate(person2, :rejected_attributes?)

    refute_predicate(person2, :accepted_attributes?)
  end
end
