require 'test_helper'

class Micro::Attributes::FeaturesTest < Minitest::Test
  With = Micro::Attributes::With
  Features = Micro::Attributes::Features

  def test_fetching_features_error
    err1 = assert_raises(ArgumentError) { Micro::Attributes.with(:foo) }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize, :keys_as_symbol', err1.message)

    err2 = assert_raises(ArgumentError) { Micro::Attributes.with() }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize, :keys_as_symbol', err2.message)
  end

  def test_fetching_all_features
    assert_equal(Features.all, Micro::Attributes.with_all_features)
    assert_equal(Features.all, Micro::Attributes::With::AMValidations_Diff_InitStrict_KeysAsSymbol)
  end

  def test_with_Diff
    klass = Class.new { include Micro::Attributes.with(:diff) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    refute_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Initialize
    klass = Class.new { include Micro::Attributes.with(:initialize) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_StrictInitialize
    klass = Class.new { include Micro::Attributes.with(initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    refute_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_ActivemodelValidations
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff_Init
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff, :initialize) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff_Init_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff, :initialize, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff_InitStrict
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff_InitStrict_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff, :keys_as_symbol, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Diff_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :diff, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Init
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :initialize) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_Init_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :initialize, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_InitStrict
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_AMValidations_InitStrict_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:activemodel_validations, :keys_as_symbol, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    assert_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Diff_Init
    klass = Class.new { include Micro::Attributes.with(:diff, :initialize) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Diff_Init_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:diff, :initialize, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Diff_InitStrict
    klass = Class.new { include Micro::Attributes.with(:diff, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    refute_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Diff_InitStrict_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:diff, :keys_as_symbol, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Diff_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:diff, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    assert_includes(klass.ancestors, Features::Diff)
    refute_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_Init_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:initialize, :keys_as_symbol) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    refute_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_with_InitStrict_KeysAsSymbol
    klass = Class.new { include Micro::Attributes.with(:keys_as_symbol, initialize: :strict) }

    assert_includes(klass.ancestors, ::Micro::Attributes)
    refute_includes(klass.ancestors, Features::Diff)
    assert_includes(klass.ancestors, Features::Initialize)
    assert_includes(klass.ancestors, Features::Initialize::Strict)
    refute_includes(klass.ancestors, Features::ActiveModelValidations)
    assert_includes(klass.ancestors, Features::KeysAsSymbol)
  end

  def test_excluding_features
    assert_equal(Micro::Attributes.without(:diff), With::AMValidations_InitStrict_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:initialize), With::AMValidations_Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(initialize: :strict), With::AMValidations_Diff_Init_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:keys_as_symbol), With::AMValidations_Diff_InitStrict)
    assert_equal(Micro::Attributes.without(:activemodel_validations), With::Diff_InitStrict_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff), With::InitStrict_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize), With::KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize, :keys_as_symbol), ::Micro::Attributes)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, initialize: :strict), With::Init_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :keys_as_symbol, initialize: :strict), With::Initialize)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :initialize), With::Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :initialize, :keys_as_symbol), With::Diff)

    assert_equal(Micro::Attributes.without(:activemodel_validations, initialize: :strict), With::Diff_Init_KeysAsSymbol)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :keys_as_symbol), With::Diff_InitStrict)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :keys_as_symbol, initialize: :strict), With::Diff_Init)

    # --

    assert_equal(Micro::Attributes.without(:diff, :initialize), With::AMValidations_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:diff, :initialize, :keys_as_symbol), With::ActiveModelValidations)

    assert_equal(Micro::Attributes.without(:diff, :keys_as_symbol), With::AMValidations_InitStrict)
    assert_equal(Micro::Attributes.without(:diff, :keys_as_symbol, initialize: :strict), With::AMValidations_Init)

    assert_equal(Micro::Attributes.without(:diff, initialize: :strict), With::AMValidations_Init_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:initialize), With::AMValidations_Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:initialize, :keys_as_symbol), With::AMValidations_Diff)

    # --

    assert_equal(Micro::Attributes.without(initialize: :strict), With::AMValidations_Diff_Init_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:keys_as_symbol, initialize: :strict), With::AMValidations_Diff_Init)
  end
end
