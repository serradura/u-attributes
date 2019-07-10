require "test_helper"

class Micro::Attributes::FeaturesTest < Minitest::Test
  Features = Micro::Attributes::Features

  def test_fetching_features
    assert_equal(Features::Diff, Micro::Attributes.features(:Diff))
    assert_equal(Features::Diff, Micro::Attributes.features('diFF'))

    assert_equal(Features::Initialize, Micro::Attributes.features(:Initialize))
    assert_equal(Features::Initialize, Micro::Attributes.features('INITIALIZE'))

    assert_equal(Features::InitializeAndDiff, Micro::Attributes.features(:diff, :initialize))
    assert_equal(Features::InitializeAndDiff, Micro::Attributes.features('initialize', :diff))
    assert_equal(Features::InitializeAndDiff, Micro::Attributes.features('INITIALIZE', 'diff'))
  end

  def test_fetching_features_error
    err = assert_raises(ArgumentError) { Micro::Attributes.features(:foo) }
    assert_equal('Invalid feature name! Available options: diff, initialize', err.message)
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

  def test_including_features
    assert_includes(A.ancestors, Features::Diff)
    refute_includes(A.ancestors, Features::Initialize)

    assert_includes(B.ancestors, Features::Initialize)
    refute_includes(B.ancestors, Features::Diff)

    assert_includes(C.ancestors, Features::Diff)
    assert_includes(C.ancestors, Features::Initialize)
  end

  def test_features_alias_method
    assert_equal(Micro::Attributes.method(:features), Micro::Attributes.method(:with))
  end
end
