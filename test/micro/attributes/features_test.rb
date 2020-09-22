require 'test_helper'

class Micro::Attributes::FeaturesTest < Minitest::Test
  # == Helpers ==
  #
  With = Micro::Attributes::With
  Features = Micro::Attributes::Features

  def check_micro_attributes_features(assert:, refute:)
    klass = Class.new { include yield }

    ([::Micro::Attributes] + Array(assert)).each { |expected| assert_includes(klass.ancestors, expected) }

    Array(refute).each { |expected| refute_includes(klass.ancestors, expected) }
  end

  # == Tests ==
  #
  def test_fetching_features_error
    err1 = assert_raises(ArgumentError) { Micro::Attributes.with(:foo) }
    assert_equal('Invalid feature name! Available options: :accept, :activemodel_validations, :diff, :initialize, :keys_as_symbol', err1.message)

    err2 = assert_raises(ArgumentError) { Micro::Attributes.with() }
    assert_equal('Invalid feature name! Available options: :accept, :activemodel_validations, :diff, :initialize, :keys_as_symbol', err2.message)
  end

  def test_fetching_all_features
    assert_equal(Features.all, Micro::Attributes.with_all_features)
    assert_equal(Features.all, Micro::Attributes::With::AcceptStrict_ActiveModelValidations_Diff_InitializeStrict_KeysAsSymbol)
  end

  def test_with_Diff
    check_micro_attributes_features(
      assert: [Features::Diff],
      refute: [Features::Initialize, Features::Initialize::Strict, Features::ActiveModelValidations, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:diff) }
  end

  def test_with_Initialize
    check_micro_attributes_features(
      assert: [Features::Initialize],
      refute: [Features::Diff, Features::Initialize::Strict, Features::ActiveModelValidations, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:initialize) }
  end

  def test_with_StrictInitialize
    check_micro_attributes_features(
      assert: [Features::Initialize, Features::Initialize::Strict],
      refute: [Features::Diff, Features::ActiveModelValidations, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(initialize: :strict) }
  end

  def test_with_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::KeysAsSymbol],
      refute: [Features::Diff, Features::Initialize, Features::Initialize::Strict, Features::ActiveModelValidations, Features::Accept]
    ) { Micro::Attributes.with(:keys_as_symbol) }
  end

  def test_with_ActivemodelValidations
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations],
      refute: [Features::Diff, Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations) }
  end

  def test_with_AMValidations_Diff
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff],
      refute: [Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff) }
  end

  def test_with_AMValidations_Diff_Init
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff, Features::Initialize],
      refute: [Features::Initialize::Strict, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff, :initialize) }
  end

  def test_with_AMValidations_Diff_Init_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff, Features::Initialize, Features::KeysAsSymbol],
      refute: [Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff, :initialize, :keys_as_symbol) }
  end

  def test_with_AMValidations_Diff_InitStrict
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff, Features::Initialize, Features::Initialize::Strict],
      refute: [Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff, initialize: :strict) }
  end

  def test_with_AMValidations_Diff_InitStrict_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff, Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol],
      refute: [Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff, :keys_as_symbol, initialize: :strict) }
  end

  def test_with_AMValidations_Diff_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Diff, Features::KeysAsSymbol],
      refute: [Features::Initialize, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :diff, :keys_as_symbol) }
  end

  def test_with_AMValidations_Init
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Initialize],
      refute: [Features::Diff, Features::KeysAsSymbol, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :initialize) }
  end

  def test_with_AMValidations_Init_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Initialize, Features::KeysAsSymbol],
      refute: [Features::Diff, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :initialize, :keys_as_symbol) }
  end

  def test_with_AMValidations_InitStrict
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Initialize, Features::Initialize::Strict],
      refute: [Features::Diff, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations,  initialize: :strict) }
  end

  def test_with_AMValidations_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::KeysAsSymbol],
      refute: [Features::Diff, Features::Initialize, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :keys_as_symbol) }
  end

  def test_with_AMValidations_InitStrict_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::ActiveModelValidations, Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol],
      refute: [Features::Diff, Features::Accept]
    ) { Micro::Attributes.with(:activemodel_validations, :keys_as_symbol, initialize: :strict) }
  end

  def test_with_Diff_Init
    check_micro_attributes_features(
      assert: [Features::Diff, Features::Initialize],
      refute: [Features::ActiveModelValidations, Features::Initialize::Strict, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:diff, :initialize) }
  end

  def test_with_Diff_Init_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::Diff, Features::Initialize, Features::KeysAsSymbol],
      refute: [Features::ActiveModelValidations, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:diff, :initialize, :keys_as_symbol) }
  end

  def test_with_Diff_InitStrict
    check_micro_attributes_features(
      assert: [Features::Diff, Features::Initialize, Features::Initialize::Strict],
      refute: [Features::ActiveModelValidations, Features::KeysAsSymbol, Features::Accept]
    ) { Micro::Attributes.with(:diff, initialize: :strict) }
  end

  def test_with_Diff_InitStrict_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::Diff, Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol],
      refute: [Features::ActiveModelValidations, Features::Accept]
    ) { Micro::Attributes.with(:diff, :keys_as_symbol, initialize: :strict) }
  end

  def test_with_Diff_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::Diff, Features::KeysAsSymbol],
      refute: [Features::ActiveModelValidations, Features::Initialize, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:diff, :keys_as_symbol) }
  end

  def test_with_Init_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::Initialize, Features::KeysAsSymbol],
      refute: [Features::ActiveModelValidations, Features::Diff, Features::Initialize::Strict, Features::Accept]
    ) { Micro::Attributes.with(:initialize, :keys_as_symbol) }
  end

  def test_with_InitStrict_KeysAsSym
    check_micro_attributes_features(
      assert: [Features::Initialize, Features::Initialize::Strict, Features::KeysAsSymbol],
      refute: [Features::ActiveModelValidations, Features::Diff, Features::Accept]
    ) { Micro::Attributes.with(:keys_as_symbol, initialize: :strict) }
  end

  def test_excluding_features
    assert_equal(Micro::Attributes.without(:diff), With::AcceptStrict_ActiveModelValidations_InitializeStrict_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:initialize), With::AcceptStrict_ActiveModelValidations_Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(initialize: :strict), With::AcceptStrict_ActiveModelValidations_Diff_Initialize_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:keys_as_symbol), With::AcceptStrict_ActiveModelValidations_Diff_InitializeStrict)
    assert_equal(Micro::Attributes.without(:activemodel_validations), With::AcceptStrict_Diff_InitializeStrict_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff), With::AcceptStrict_InitializeStrict_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize), With::AcceptStrict_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize, :keys_as_symbol), With::AcceptStrict)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, initialize: :strict), With::AcceptStrict_Initialize_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :keys_as_symbol, initialize: :strict), With::AcceptStrict_Initialize)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :initialize), With::AcceptStrict_Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :initialize, :keys_as_symbol), With::AcceptStrict_Diff)

    assert_equal(Micro::Attributes.without(:activemodel_validations, initialize: :strict), With::AcceptStrict_Diff_Initialize_KeysAsSymbol)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :keys_as_symbol), With::AcceptStrict_Diff_InitializeStrict)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :keys_as_symbol, initialize: :strict), With::AcceptStrict_Diff_Initialize)

    # --

    assert_equal(Micro::Attributes.without(:diff, :initialize), With::AcceptStrict_ActiveModelValidations_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:diff, :initialize, :keys_as_symbol), With::AcceptStrict_ActiveModelValidations)

    assert_equal(Micro::Attributes.without(:diff, :keys_as_symbol), With::AcceptStrict_ActiveModelValidations_InitializeStrict)
    assert_equal(Micro::Attributes.without(:diff, :keys_as_symbol, initialize: :strict), With::AcceptStrict_ActiveModelValidations_Initialize)

    assert_equal(Micro::Attributes.without(:diff, initialize: :strict), With::AcceptStrict_ActiveModelValidations_Initialize_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:initialize), With::AcceptStrict_ActiveModelValidations_Diff_KeysAsSymbol)
    assert_equal(Micro::Attributes.without(:initialize, :keys_as_symbol), With::AcceptStrict_ActiveModelValidations_Diff)

    # --

    assert_equal(Micro::Attributes.without(initialize: :strict), With::AcceptStrict_ActiveModelValidations_Diff_Initialize_KeysAsSymbol)

    # --

    assert_equal(Micro::Attributes.without(:keys_as_symbol, initialize: :strict), With::AcceptStrict_ActiveModelValidations_Diff_Initialize)
  end
end
