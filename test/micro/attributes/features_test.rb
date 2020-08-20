require 'test_helper'

class Micro::Attributes::FeaturesTest < Minitest::Test
  With = Micro::Attributes::With
  Features = Micro::Attributes::Features

  def test_fetching_features_error
    err1 = assert_raises(ArgumentError) { Micro::Attributes.with(:foo) }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize', err1.message)

    err2 = assert_raises(ArgumentError) { Micro::Attributes.with() }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize', err2.message)
  end

  def test_fetching_all_features
    assert_equal(Features.all, Micro::Attributes.with_all_features)
    assert_equal(Features.all, Micro::Attributes::With::ActiveModelValidationsAndDiffAndStrictInitialize)
  end

  class A
    include Micro::Attributes.with(:diff)
  end

  class B
    include Micro::Attributes.with(:initialize)
  end

  class C
    include Micro::Attributes.with(:initialize, :diff)
  end

  class CStrict
    include Micro::Attributes.with(:diff, initialize: :strict)
  end

  class D
    include Micro::Attributes.with(:initialize, :activemodel_validations)
  end

  class DStrict
    include Micro::Attributes.with(:activemodel_validations, initialize: :strict)
  end

  class E
    include Micro::Attributes.with(:diff, :activemodel_validations)
  end

  class F
    include Micro::Attributes.with(:initialize, :diff, :activemodel_validations)
  end

  class FStrict
    include Micro::Attributes.with(:diff, :activemodel_validations, initialize: :strict)
  end

  def test_including_features
    assert_includes(A.ancestors, ::Micro::Attributes)
    assert_includes(A.ancestors, Features::Diff)
    refute_includes(A.ancestors, Features::Initialize)
    refute_includes(C.ancestors, Features::Initialize::Strict)
    refute_includes(A.ancestors, Features::ActiveModelValidations)

    assert_includes(B.ancestors, ::Micro::Attributes)
    assert_includes(B.ancestors, Features::Initialize)
    refute_includes(B.ancestors, Features::Diff)
    refute_includes(C.ancestors, Features::Initialize::Strict)
    refute_includes(B.ancestors, Features::ActiveModelValidations)

    assert_includes(C.ancestors, ::Micro::Attributes)
    assert_includes(C.ancestors, Features::Initialize)
    assert_includes(C.ancestors, Features::Diff)
    refute_includes(C.ancestors, Features::Initialize::Strict)
    refute_includes(C.ancestors, Features::ActiveModelValidations)

    assert_includes(CStrict.ancestors, ::Micro::Attributes)
    assert_includes(CStrict.ancestors, Features::Initialize)
    assert_includes(CStrict.ancestors, Features::Diff)
    assert_includes(CStrict.ancestors, Features::Initialize::Strict)
    refute_includes(CStrict.ancestors, Features::ActiveModelValidations)

    assert_includes(D.ancestors, ::Micro::Attributes)
    refute_includes(D.ancestors, Features::Diff)
    assert_includes(D.ancestors, Features::Initialize)
    refute_includes(D.ancestors, Features::Initialize::Strict)
    assert_includes(D.ancestors, Features::ActiveModelValidations)

    assert_includes(DStrict.ancestors, ::Micro::Attributes)
    assert_includes(DStrict.ancestors, Features::Initialize)
    refute_includes(DStrict.ancestors, Features::Diff)
    assert_includes(DStrict.ancestors, Features::Initialize::Strict)
    assert_includes(DStrict.ancestors, Features::ActiveModelValidations)

    assert_includes(E.ancestors, ::Micro::Attributes)
    refute_includes(E.ancestors, Features::Initialize)
    assert_includes(E.ancestors, Features::Diff)
    refute_includes(E.ancestors, Features::Initialize::Strict)
    assert_includes(E.ancestors, Features::ActiveModelValidations)

    assert_includes(F.ancestors, ::Micro::Attributes)
    assert_includes(F.ancestors, Features::Diff)
    assert_includes(F.ancestors, Features::Initialize)
    refute_includes(F.ancestors, Features::Initialize::Strict)
    assert_includes(F.ancestors, Features::ActiveModelValidations)

    assert_includes(FStrict.ancestors, ::Micro::Attributes)
    assert_includes(FStrict.ancestors, Features::Initialize)
    assert_includes(FStrict.ancestors, Features::Diff)
    assert_includes(FStrict.ancestors, Features::Initialize::Strict)
    assert_includes(FStrict.ancestors, Features::ActiveModelValidations)
  end

  def test_excluding_features
    assert_equal(Micro::Attributes.without(:diff), Micro::Attributes::With::ActiveModelValidationsAndStrictInitialize)
    assert_equal(Micro::Attributes.without(:initialize), With::ActiveModelValidationsAndDiff)
    assert_equal(Micro::Attributes.without(initialize: :strict), With::ActiveModelValidationsAndDiffAndInitialize)
    assert_equal(Micro::Attributes.without(:activemodel_validations), With::DiffAndStrictInitialize)

    assert_equal(Micro::Attributes.without(:diff, :initialize), Micro::Attributes::With::ActiveModelValidations)
    assert_equal(Micro::Attributes.without(:diff, initialize: :strict), Micro::Attributes::With::ActiveModelValidationsAndInitialize)
    assert_equal(Micro::Attributes.without(:diff, :activemodel_validations), Micro::Attributes::With::StrictInitialize)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :initialize), Micro::Attributes::With::Diff)
    assert_equal(Micro::Attributes.without(:activemodel_validations, initialize: :strict), Micro::Attributes::With::DiffAndInitialize)

    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize), Micro::Attributes)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, :initialize, initialize: :strict), Micro::Attributes)
    assert_equal(Micro::Attributes.without(:activemodel_validations, :diff, initialize: :strict), Micro::Attributes::With::Initialize)
  end

  def test_including_initialize_features
    assert_equal(Micro::Attributes.with(initialize: :strict), With::StrictInitialize)
    assert_equal(Micro::Attributes.with(:diff, initialize: :strict), With::DiffAndStrictInitialize)
    assert_equal(Micro::Attributes.with(:activemodel_validations, initialize: :strict), With::ActiveModelValidationsAndStrictInitialize)
    assert_equal(Micro::Attributes.with(:activemodel_validations, :diff, initialize: :strict), With::ActiveModelValidationsAndDiffAndStrictInitialize)
  end
end
