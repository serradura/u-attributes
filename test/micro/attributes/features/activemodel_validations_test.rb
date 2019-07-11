require "test_helper"

class Micro::Attributes::Features::ActiveModelValidationsTest < MiniTest::Test
  def test_load_error
    Micro::Attributes.with(:initialize, :activemodel_validations)
    assert(true)
  end

  if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') < '6.1'

    require "active_model"
    require "active_model/naming"
    require "active_model/translation"
    require "active_model/validations"
    class A
      include Micro::Attributes.to_initialize(activemodel_validations: true)

      attribute :a
      validates :a, presence: true
    end

    class B
      include Micro::Attributes.with(:initialize, :activemodel_validations)

      attribute :b
      validates! :b, presence: true
    end

    def test_validates
      instance = A.new(a: '')

      refute(instance.valid?)
    end

    def test_validates!
      err = assert_raises(ActiveModel::StrictValidationFailed) { B.new(B: '') }
      assert_equal("B can't be blank", err.message)
    end

  end
end
