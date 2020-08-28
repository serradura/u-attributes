require 'test_helper'

class Micro::Attributes::Features::ActiveModelValidationsTest < MiniTest::Test
  def test_load_error
    Class.new do
      include Micro::Attributes::With::ActiveModelValidations
    end
    assert(true)
  end

  if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') < '6.1'

    require 'active_model'
    require 'active_model/naming'
    require 'active_model/translation'
    require 'active_model/validations'

    class A
      include Micro::Attributes.with(:activemodel_validations)

      attribute :a, validates: { presence: true }
    end

    class B
      include Micro::Attributes.with(:initialize, :activemodel_validations)

      attribute :b, validates: { presence: true, strict: true }
    end

    class C
      include Micro::Attributes.with_all_features

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

  end
end
