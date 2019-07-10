require "test_helper"


class Micro::Attributes::Features::ActiveModelValidations::LoadErrorTest < MiniTest::Test
  def test_load_error
    Micro::Attributes.with(:initialize, :activemodel_validations)
    assert(true)
  end
end
