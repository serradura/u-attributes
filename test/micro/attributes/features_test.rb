require "test_helper"

class Micro::Attributes::FeaturesTest < Minitest::Test
  With = Micro::Attributes::With
  Features = Micro::Attributes::Features

  def test_fetching_one_feature
    assert_equal(With::Diff, Micro::Attributes.feature(:Diff))
    assert_equal(With::Diff, Micro::Attributes.feature('diFF'))

    assert_equal(With::Initialize, Micro::Attributes.feature(:Initialize))
    assert_equal(With::Initialize, Micro::Attributes.feature('INITIALIZE'))

    err = assert_raises(ArgumentError) { Micro::Attributes.feature('INITIALIZE', :initialize) }
    if RUBY_VERSION < '2.3.0'
      assert_equal('wrong number of arguments (2 for 1)', err.message)
    else
      assert_equal('wrong number of arguments (given 2, expected 1)', err.message)
    end
  end

  def test_fetching_many_features
    assert_equal(With::Diff, Micro::Attributes.features(:Diff))
    assert_equal(With::Diff, Micro::Attributes.features('diFF'))

    assert_equal(With::Initialize, Micro::Attributes.features(:Initialize))
    assert_equal(With::Initialize, Micro::Attributes.features('INITIALIZE'))

    assert_equal(With::Initialize, Micro::Attributes.features(:Initialize, 'initialize'))
    assert_equal(With::Initialize, Micro::Attributes.features('INITIALIZE', :initialize))

    assert_equal(With::DiffAndInitialize, Micro::Attributes.features(:diff, :initialize))
    assert_equal(With::DiffAndInitialize, Micro::Attributes.features('initialize', :diff))
    assert_equal(With::DiffAndInitialize, Micro::Attributes.features('INITIALIZE', 'diff'))
  end

  def test_fetching_features_error
    err1 = assert_raises(ArgumentError) { Micro::Attributes.features(:foo) }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize, :strict_initialize', err1.message)

    err2 = assert_raises(ArgumentError) { Micro::Attributes.with() }
    assert_equal('Invalid feature name! Available options: :activemodel_validations, :diff, :initialize, :strict_initialize', err2.message)
  end

  def test_fetching_all_features
    assert_equal(Features.all, Micro::Attributes.features)
    assert_equal(Features.all, Micro::Attributes::With::ActiveModelValidationsAndDiffAndStrictInitialize)
  end

  class A
    include Micro::Attributes.features(:diff)
  end

  class B
    include Micro::Attributes.features(:initialize)
  end

  class C
    include Micro::Attributes.features(:initialize, :diff)
  end

  class CStrict
    include Micro::Attributes.features(:strict_initialize, :diff)
  end

  class D
    include Micro::Attributes.features(:initialize, :activemodel_validations)
  end

  class DStrict
    include Micro::Attributes.features(:strict_initialize, :activemodel_validations)
  end

  class E
    include Micro::Attributes.features(:diff, :activemodel_validations)
  end

  class F
    include Micro::Attributes.features(:initialize, :diff, :activemodel_validations)
  end

  class FStrict
    include Micro::Attributes.features(:strict_initialize, :diff, :activemodel_validations)
  end

  def test_including_features
    assert_includes(A.ancestors, ::Micro::Attributes)
    assert_includes(A.ancestors, Features::Diff)
    refute_includes(A.ancestors, Features::Initialize)
    refute_includes(C.ancestors, Features::StrictInitialize)
    refute_includes(A.ancestors, Features::ActiveModelValidations)

    assert_includes(B.ancestors, ::Micro::Attributes)
    assert_includes(B.ancestors, Features::Initialize)
    refute_includes(B.ancestors, Features::Diff)
    refute_includes(C.ancestors, Features::StrictInitialize)
    refute_includes(B.ancestors, Features::ActiveModelValidations)

    assert_includes(C.ancestors, ::Micro::Attributes)
    assert_includes(C.ancestors, Features::Initialize)
    assert_includes(C.ancestors, Features::Diff)
    refute_includes(C.ancestors, Features::StrictInitialize)
    refute_includes(C.ancestors, Features::ActiveModelValidations)

    assert_includes(CStrict.ancestors, ::Micro::Attributes)
    assert_includes(CStrict.ancestors, Features::Initialize)
    assert_includes(CStrict.ancestors, Features::Diff)
    assert_includes(CStrict.ancestors, Features::StrictInitialize)
    refute_includes(CStrict.ancestors, Features::ActiveModelValidations)

    assert_includes(D.ancestors, ::Micro::Attributes)
    refute_includes(D.ancestors, Features::Diff)
    assert_includes(D.ancestors, Features::Initialize)
    refute_includes(D.ancestors, Features::StrictInitialize)
    assert_includes(D.ancestors, Features::ActiveModelValidations)

    assert_includes(DStrict.ancestors, ::Micro::Attributes)
    assert_includes(DStrict.ancestors, Features::Initialize)
    refute_includes(DStrict.ancestors, Features::Diff)
    assert_includes(DStrict.ancestors, Features::StrictInitialize)
    assert_includes(DStrict.ancestors, Features::ActiveModelValidations)

    assert_includes(E.ancestors, ::Micro::Attributes)
    refute_includes(E.ancestors, Features::Initialize)
    assert_includes(E.ancestors, Features::Diff)
    refute_includes(E.ancestors, Features::StrictInitialize)
    assert_includes(E.ancestors, Features::ActiveModelValidations)

    assert_includes(F.ancestors, ::Micro::Attributes)
    assert_includes(F.ancestors, Features::Diff)
    assert_includes(F.ancestors, Features::Initialize)
    refute_includes(F.ancestors, Features::StrictInitialize)
    assert_includes(F.ancestors, Features::ActiveModelValidations)

    assert_includes(FStrict.ancestors, ::Micro::Attributes)
    assert_includes(FStrict.ancestors, Features::Initialize)
    assert_includes(FStrict.ancestors, Features::Diff)
    assert_includes(FStrict.ancestors, Features::StrictInitialize)
    assert_includes(FStrict.ancestors, Features::ActiveModelValidations)
  end
end
