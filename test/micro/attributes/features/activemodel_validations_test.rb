require 'test_helper'

class Micro::Attributes::Features::ActiveModelValidationsTest < MiniTest::Test
  def test_load_error
    Class.new do
      include Micro::Attributes::With::ActiveModelValidations
    end
    assert(true)
  end

  if ENV.fetch('ACTIVEMODEL_VERSION', '7') < '7'

    require 'active_model'
    require 'active_model/naming'
    require 'active_model/translation'
    require 'active_model/validations'

    class A
      include Micro::Attributes.with(:activemodel_validations)

      attribute :a, validates: { presence: true }

      def initialize(data)
        self.attributes = data
      end
    end

    class B
      include Micro::Attributes.with(:initialize, :activemodel_validations)

      attribute :b, validates: { presence: true, strict: true }
    end

    class C
      include Micro::Attributes.with(:initialize, :accept, :activemodel_validations)

      attributes :c
      validates! :c, presence: true
    end

    class D
      include Micro::Attributes.with(:initialize, :activemodel_validations)

      attribute :a, validate: :must_be_present

      def must_be_present
        return if a.present?

        errors.add(:a, "can't be blank")
      end
    end

    def test_validates
      a_instance = A.new(a: '')
      d_instance = D.new(a: '')

      refute(a_instance.valid?)
      refute(d_instance.valid?)
    end

    def test_validates!
      err1 = assert_raises(ActiveModel::StrictValidationFailed) { B.new(b: '') }
      assert_equal("B can't be blank", err1.message)

      err2 = assert_raises(ActiveModel::StrictValidationFailed) { C.new(c: nil) }
      assert_equal("C can't be blank", err2.message)
    end

    class Add
      include Micro::Attributes.with(:activemodel_validations)

      attribute :a, default: 1, validates: { kind: Numeric }
      attribute :b, default: 1, validates: { kind: Numeric }

      def initialize(data)
        self.attributes = data
      end

      def call
        return 0 if errors.present?

        a + b
      end
    end

    def test_defaults_defined_via_the_attribute_method
      assert_equal(2, Add.new({}).call)
      assert_equal(3, Add.new(a: 2).call)
      assert_equal(4, Add.new(b: 3).call)
      assert_equal(5, Add.new(a: 2, b: 3).call)

      # --

      assert_equal(0, Add.new(a: '2').call)
      assert_equal(0, Add.new(b: '3').call)
      assert_equal(0, Add.new(a: /2/, b: 3).call)
    end

    class Sum
      include Micro::Attributes.with(:initialize, :activemodel_validations)

      attributes :a, :b, default: 2, validates: { kind: Numeric }

      def call
        return 0 if errors.present?

        a + b
      end
    end

    def test_defaults_defined_via_the_attributes_method
      assert_equal(4, Sum.new({}).call)
      assert_equal(3, Sum.new(a: 1).call)
      assert_equal(5, Sum.new(b: 3).call)
      assert_equal(5, Sum.new(a: 2, b: 3).call)

      # --

      assert_equal(0, Sum.new(a: '2').call)
      assert_equal(0, Sum.new(b: '3').call)
      assert_equal(0, Sum.new(a: /2/, b: 3).call)
    end

    class CalcWithIndifferentAccess
      include Micro::Attributes.with(:activemodel_validations, :accept)

      attribute :a, accept: Numeric, validates: { numericality: { only_integer: true } }
      attribute :b, accept: Numeric, validates: { numericality: { only_integer: true } }

      def initialize(data)
        self.attributes = data
      end

      def sum
        return if attributes_errors?

        return a + b
      end
    end

    def test_accept_and_activemodel_validation_with_indifferent_access
      calc1 = CalcWithIndifferentAccess.new(a: 1, b: 2)

      assert_equal(3, calc1.sum)

      assert_equal({}, calc1.attributes_errors)
      assert_equal([], calc1.rejected_attributes)
      assert_equal(['a', 'b'], calc1.accepted_attributes)

      refute_predicate(calc1, :attributes_errors?)
      refute_predicate(calc1, :rejected_attributes?)
      assert_predicate(calc1, :accepted_attributes?)

      # -- --

      calc2 = CalcWithIndifferentAccess.new(a: '1', b: 2)

      assert_nil(calc2.sum)

      assert_equal({'a' => 'expected to be a kind of Numeric'}, calc2.attributes_errors)
      assert_equal(['a'], calc2.rejected_attributes)
      assert_equal(['b'], calc2.accepted_attributes)

      assert_predicate(calc2, :attributes_errors?)
      assert_predicate(calc2, :rejected_attributes?)
      refute_predicate(calc2, :accepted_attributes?)

      # -- --

      calc3 = CalcWithIndifferentAccess.new(a: 1.0, b: 2)

      assert_nil(calc3.sum)

      assert_equal({'a' => 'must be an integer'}, calc3.attributes_errors)
      assert_equal(['a'], calc3.rejected_attributes)
      assert_equal(['b'], calc3.accepted_attributes)

      assert_predicate(calc3, :attributes_errors?)
      assert_predicate(calc3, :rejected_attributes?)
      refute_predicate(calc3, :accepted_attributes?)

      # -- --

      calc4 = CalcWithIndifferentAccess.new(a: '1.0', b: 2.0)

      assert_nil(calc4.sum)

      assert_equal({ 'a' => 'expected to be a kind of Numeric' }, calc4.attributes_errors)
      assert_equal(['a'], calc4.rejected_attributes)
      assert_equal(['b'], calc4.accepted_attributes)

      assert_predicate(calc4, :attributes_errors?)
      assert_predicate(calc4, :rejected_attributes?)
      refute_predicate(calc4, :accepted_attributes?)

      # -- --

      calc5 = CalcWithIndifferentAccess.new(a: 1.0, b: 2.0)

      assert_nil(calc5.sum)

      assert_equal({ 'a' => 'must be an integer', 'b' => 'must be an integer'}, calc5.attributes_errors)
      assert_equal(['a', 'b'], calc5.rejected_attributes)
      assert_equal([], calc5.accepted_attributes)

      assert_predicate(calc5, :attributes_errors?)
      assert_predicate(calc5, :rejected_attributes?)
      refute_predicate(calc5, :accepted_attributes?)
    end

    class CalcWithKeysAsSymbol
      include Micro::Attributes.with(:accept, :activemodel_validations, :keys_as_symbol)

      attributes :a, :b, accept: Numeric

      validates :a, :b, numericality: { only_integer: true }

      def initialize(data)
        self.attributes = data
      end

      def sum
        return if attributes_errors?

        return a + b
      end
    end

    def test_accept_and_activemodel_validation_with_keys_as_symbol
      calc1 = CalcWithKeysAsSymbol.new(a: 1, b: 2)

      assert_equal(3, calc1.sum)

      assert_equal({}, calc1.attributes_errors)
      assert_equal([], calc1.rejected_attributes)
      assert_equal([:a, :b], calc1.accepted_attributes)

      refute_predicate(calc1, :attributes_errors?)
      refute_predicate(calc1, :rejected_attributes?)
      assert_predicate(calc1, :accepted_attributes?)

      # -- --

      calc2 = CalcWithKeysAsSymbol.new(a: '1', b: 2)

      assert_nil(calc2.sum)

      assert_equal({a: 'expected to be a kind of Numeric'}, calc2.attributes_errors)
      assert_equal([:a], calc2.rejected_attributes)
      assert_equal([:b], calc2.accepted_attributes)

      assert_predicate(calc2, :attributes_errors?)
      assert_predicate(calc2, :rejected_attributes?)
      refute_predicate(calc2, :accepted_attributes?)

      # -- --

      calc3 = CalcWithKeysAsSymbol.new(a: 1.0, b: 2)

      assert_nil(calc3.sum)

      assert_equal({a: 'must be an integer'}, calc3.attributes_errors)
      assert_equal([:a], calc3.rejected_attributes)
      assert_equal([:b], calc3.accepted_attributes)

      assert_predicate(calc3, :attributes_errors?)
      assert_predicate(calc3, :rejected_attributes?)
      refute_predicate(calc3, :accepted_attributes?)

      # -- --

      calc4 = CalcWithKeysAsSymbol.new(a: '1.0', b: 2.0)

      assert_nil(calc4.sum)

      assert_equal({ a: 'expected to be a kind of Numeric' }, calc4.attributes_errors)
      assert_equal([:a], calc4.rejected_attributes)
      assert_equal([:b], calc4.accepted_attributes)

      assert_predicate(calc4, :attributes_errors?)
      assert_predicate(calc4, :rejected_attributes?)
      refute_predicate(calc4, :accepted_attributes?)

      # -- --

      calc5 = CalcWithKeysAsSymbol.new(a: 1.0, b: 2.0)

      assert_nil(calc5.sum)

      assert_equal({ a: 'must be an integer', b: 'must be an integer'}, calc5.attributes_errors)
      assert_equal([:a, :b], calc5.rejected_attributes)
      assert_equal([], calc5.accepted_attributes)

      assert_predicate(calc5, :attributes_errors?)
      assert_predicate(calc5, :rejected_attributes?)
      refute_predicate(calc5, :accepted_attributes?)
    end

    class CalcStrictWithIndifferentAccess
      include Micro::Attributes.with(:activemodel_validations, accept: :strict)

      attributes :a, :b, accept: Numeric, validates: { numericality: { only_integer: true } }

      def initialize(data)
        self.attributes = data
      end

      def sum
        return if attributes_errors?

        return a + b
      end
    end

    def test_accept_strict_and_activemodel_validation_with_indifferent_access
      err = assert_raises(ArgumentError) { CalcStrictWithIndifferentAccess.new(a: '1.0', b: 2.0) }
      err_message =
        "One or more attributes were rejected. Errors:\n"\
        "* \"a\" expected to be a kind of Numeric"

      assert_equal(err_message, err.message)

      # --

      calc = CalcStrictWithIndifferentAccess.new(a: 1.0, b: 2)

      assert_nil(calc.sum)

      assert_equal({ 'a' => 'must be an integer' }, calc.attributes_errors)
      assert_equal(['a'], calc.rejected_attributes)
      assert_equal(['b'], calc.accepted_attributes)

      assert_predicate(calc, :attributes_errors?)
      assert_predicate(calc, :rejected_attributes?)
      refute_predicate(calc, :accepted_attributes?)
    end

    class CalcStrictWithKeysAsSymbol
      include Micro::Attributes.with(:activemodel_validations, :keys_as_symbol, accept: :strict)

      attributes :a, :b, accept: Numeric, validates: { numericality: { only_integer: true } }

      def initialize(data)
        self.attributes = data
      end

      def sum
        return if attributes_errors?

        return a + b
      end
    end

    def test_accept_strict_and_activemodel_validation_with_keys_as_symbol
      err = assert_raises(ArgumentError) { CalcStrictWithKeysAsSymbol.new(a: 1.0, b: '2.0') }
      err_message =
        "One or more attributes were rejected. Errors:\n"\
        "* :b expected to be a kind of Numeric"

      assert_equal(err_message, err.message)

      # --

      calc = CalcStrictWithKeysAsSymbol.new(a: 1, b: 2.0 )

      assert_nil(calc.sum)

      assert_equal({ b: 'must be an integer' }, calc.attributes_errors)
      assert_equal([:b], calc.rejected_attributes)
      assert_equal([:a], calc.accepted_attributes)

      assert_predicate(calc, :attributes_errors?)
      assert_predicate(calc, :rejected_attributes?)
      refute_predicate(calc, :accepted_attributes?)
    end
  end
end
