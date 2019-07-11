require "test_helper"

class Micro::Attributes::FeaturesTest < Minitest::Test
  With = Micro::Attributes::With
  Features = Micro::Attributes::Features

  def test_fetching_features
    assert_equal(With::Diff, Micro::Attributes.features(:Diff))
    assert_equal(With::Diff, Micro::Attributes.features('diFF'))

    assert_equal(With::Initialize, Micro::Attributes.features(:Initialize))
    assert_equal(With::Initialize, Micro::Attributes.features('INITIALIZE'))

    assert_equal(With::DiffAndInitialize, Micro::Attributes.features(:diff, :initialize))
    assert_equal(With::DiffAndInitialize, Micro::Attributes.features('initialize', :diff))
    assert_equal(With::DiffAndInitialize, Micro::Attributes.features('INITIALIZE', 'diff'))
  end

  def test_fetching_features_error
    err1 = assert_raises(ArgumentError) { Micro::Attributes.features(:foo) }
    assert_equal('Invalid feature name! Available options: :initialize, :diff, :activemodel_validations', err1.message)

    err2 = assert_raises(ArgumentError) { Micro::Attributes.with() }
    assert_equal('Invalid feature name! Available options: :initialize, :diff, :activemodel_validations', err2.message)
  end

  def test_fetching_all_features
    assert_equal(Features.all, Micro::Attributes.features)
    assert_equal(Features.all, Micro::Attributes.with(:initialize, :diff, :activemodel_validations))
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

  class D
    include Micro::Attributes.features(:initialize, :activemodel_validations)
  end

  class E
    include Micro::Attributes.features(:diff, :activemodel_validations)
  end

  class F
    include Micro::Attributes.features(:initialize, :diff, :activemodel_validations)
  end

  def test_including_features
    assert_includes(A.ancestors, ::Micro::Attributes)
    assert_includes(A.ancestors, Features::Diff)
    refute_includes(A.ancestors, Features::Initialize)
    refute_includes(A.ancestors, Features::ActiveModelValidations)

    assert_includes(B.ancestors, ::Micro::Attributes)
    assert_includes(B.ancestors, Features::Initialize)
    refute_includes(B.ancestors, Features::Diff)
    refute_includes(B.ancestors, Features::ActiveModelValidations)

    assert_includes(C.ancestors, ::Micro::Attributes)
    assert_includes(C.ancestors, Features::Diff)
    assert_includes(C.ancestors, Features::Initialize)
    refute_includes(C.ancestors, Features::ActiveModelValidations)

    assert_includes(D.ancestors, ::Micro::Attributes)
    refute_includes(D.ancestors, Features::Diff)
    assert_includes(D.ancestors, Features::Initialize)
    assert_includes(D.ancestors, Features::ActiveModelValidations)

    assert_includes(E.ancestors, ::Micro::Attributes)
    assert_includes(E.ancestors, Features::Diff)
    refute_includes(E.ancestors, Features::Initialize)
    assert_includes(E.ancestors, Features::ActiveModelValidations)

    assert_includes(F.ancestors, ::Micro::Attributes)
    assert_includes(F.ancestors, Features::Diff)
    assert_includes(F.ancestors, Features::Initialize)
    assert_includes(F.ancestors, Features::ActiveModelValidations)
  end
end
