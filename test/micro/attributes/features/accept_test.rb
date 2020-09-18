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

  def test_the_accept_with_predicate_and_indifferent_access
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

  def test_the_accept_with_predicate_and_keys_as_symbol
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

  class ValidateAfterDefaultValueWithIndifferentAccess
    include Micro::Attributes.with(:accept, :initialize)

    attribute :value, reject: Numeric, default: -> value { value.to_s }
  end

  class ValidateAfterDefaultValueKeysAsSymbol
    include Micro::Attributes.with(:accept, :initialize, :keys_as_symbol)

    attribute :value, reject: Numeric, default: -> value { value.to_s }
  end

  def test_that_the_validation_runs_after_resolve_the_default_value
    obj1 = ValidateAfterDefaultValueWithIndifferentAccess.new(value: 1)
    obj2 = ValidateAfterDefaultValueKeysAsSymbol.new(value: 1.0)

    assert_equal(['value'], obj1.accepted_attributes)
    assert_equal([:value], obj2.accepted_attributes)

    [obj1, obj2].each do |obj|
      assert_equal({}, obj.attributes_errors)
      assert_equal([], obj.rejected_attributes)

      refute_predicate(obj, :attributes_errors?)
      refute_predicate(obj, :rejected_attributes?)
      assert_predicate(obj, :accepted_attributes?)
    end
  end

  class ValidationAllowsNilWithIndifferentAccess
    include Micro::Attributes.with(:accept, :initialize)

    attribute :number, accept: Numeric, allow_nil: true
  end

  class ValidationAllowsNilKeysAsSymbol
    include Micro::Attributes.with(:accept, :initialize, :keys_as_symbol)

    attribute :number, accept: Numeric, allow_nil: true
  end

  def test_that_the_validation_skip_nil_if_it_was_allowed
    nil1 = ValidationAllowsNilWithIndifferentAccess.new(number: nil)
    nil2 = ValidationAllowsNilKeysAsSymbol.new(value: nil)

    assert_equal(['number'], nil1.accepted_attributes)
    assert_equal([:number], nil2.accepted_attributes)

    [nil1, nil2].each do |obj|
      assert_equal({}, obj.attributes_errors)
      assert_equal([], obj.rejected_attributes)

      refute_predicate(obj, :attributes_errors?)
      refute_predicate(obj, :rejected_attributes?)
      assert_predicate(obj, :accepted_attributes?)
    end

    # --

    obj1 = ValidationAllowsNilWithIndifferentAccess.new(number: '1')
    obj2 = ValidationAllowsNilKeysAsSymbol.new(number: :a)

    assert_equal(['number'], obj1.rejected_attributes)
    assert_equal({'number' => 'expected to be a kind of Numeric'}, obj1.attributes_errors)

    assert_equal([:number], obj2.rejected_attributes)
    assert_equal({number: 'expected to be a kind of Numeric'}, obj2.attributes_errors)

    [obj1, obj2].each do |obj|
      assert_predicate(obj, :attributes_errors?)
      assert_predicate(obj, :rejected_attributes?)
      refute_predicate(obj, :accepted_attributes?)
    end
  end

  PROC_HANDLER = proc { 1 }
  LAMBDA_HANDLER = lambda { 2 }

  class SkipDefaultValueResolutionWhenAcceptAProcWithIndifferentAccess
    include Micro::Attributes.with(:accept, :initialize)

    attribute :str, accept: String, default: -> value { value.to_s }
    attribute :proc_handler, accept: Proc, default: PROC_HANDLER
    attribute :lambda_handler, accept: Proc, default: LAMBDA_HANDLER
  end

  class SkipDefaultValueResolutionWhenAcceptAProcWithKeysAsSymbol
    include Micro::Attributes.with(:accept, :initialize, :keys_as_symbol)

    attribute :str, accept: String, default: -> value { value.to_s }
    attribute :proc_handler, accept: Proc, default: PROC_HANDLER
    attribute :lambda_handler, accept: Proc, default: LAMBDA_HANDLER
  end

  def test_that_the_validation_skip_nil_if_it_was_allowed
    obj1 = SkipDefaultValueResolutionWhenAcceptAProcWithIndifferentAccess.new(str: 0)
    obj2 = SkipDefaultValueResolutionWhenAcceptAProcWithKeysAsSymbol.new(str: 0)

    assert_equal(['str', 'proc_handler', 'lambda_handler'], obj1.accepted_attributes)
    assert_equal([:str, :proc_handler, :lambda_handler], obj2.accepted_attributes)

    [obj1, obj2].each do |obj|
      assert_equal('0', obj.str)
      assert_equal(PROC_HANDLER, obj.proc_handler)
      assert_equal(1, obj.proc_handler.call)

      assert_equal(LAMBDA_HANDLER, obj.lambda_handler)
      assert_equal(2, obj.lambda_handler.call)

      assert_equal({}, obj.attributes_errors)
      assert_equal([], obj.rejected_attributes)

      refute_predicate(obj, :attributes_errors?)
      refute_predicate(obj, :rejected_attributes?)
      assert_predicate(obj, :accepted_attributes?)
    end

    # --

    obj3 = SkipDefaultValueResolutionWhenAcceptAProcWithKeysAsSymbol.new(str: 0, proc_handler: proc { 3 })
    obj4 = SkipDefaultValueResolutionWhenAcceptAProcWithKeysAsSymbol.new(str: 0, lambda_handler: -> { 4 })

    assert_predicate(obj3, :accepted_attributes?)
    assert_predicate(obj4, :accepted_attributes?)

    refute_equal(PROC_HANDLER, obj3.proc_handler)
    assert_equal(3, obj3.proc_handler.call)

    refute_equal(LAMBDA_HANDLER, obj4.lambda_handler)
    assert_equal(4, obj4.lambda_handler.call)
  end
end
