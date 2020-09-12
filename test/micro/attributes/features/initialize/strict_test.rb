require 'test_helper'

class Micro::Attributes::Features::InitializeStrictTest < Minitest::Test
  class Foo
    include Micro::Attributes::With::StrictInitialize

    attribute :a
    attribute 'b'
  end

  class Bar
    include Micro::Attributes.with(initialize: :strict)

    attribute :a
    attribute :b, default: 'B'
    attribute 'c', default: 'C'
  end

  BValue = lambda { |value| value || 'B' }

  class Buz
    include Micro::Attributes
      .with(:activemodel_validations, :diff, initialize: :strict)

    attribute :a, default: -> v { v.to_sym }
    attribute :b, default: BValue
    attribute 'c', default: 'C'
  end

  def test_the_constructor_argument_validation
    [Foo, Bar].each do |klass|
      error = assert_raises(Kind::Error) { klass.new(1) }

      assert_equal('1 expected to be a kind of Hash', error.message)
    end
  end

  def test_keywords_missing_validation
    err0 = assert_raises(ArgumentError) { Foo.new({}) }
    assert_equal('missing keywords: :a, :b', err0.message)

    err1 = assert_raises(ArgumentError) { Foo.new(a: 'a') }
    assert_equal('missing keyword: :b', err1.message)

    err2 = assert_raises(ArgumentError) { Bar.new({}) }
    assert_equal('missing keyword: :a', err2.message)
  end

  def test_build_new_instance_after_set_one_attribute
    instance_1 = Foo.new(a: 'a', b: nil)
    instance_2 = instance_1.with_attribute(:a, 'A')
    instance_3 = instance_1.with_attribute(:a, '@')

    assert_equal('a', instance_1.a)
    assert_equal('A', instance_2.a)
    assert_equal('@', instance_3.a)

    assert_nil(instance_1.b)
    assert_nil(instance_2.b)
    assert_nil(instance_3.b)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)

    # ---

    instance_1 = Buz.new(a: 'a')
    instance_2 = instance_1.with_attribute(:a, 'A')
    instance_3 = instance_1.with_attribute(:a, '@')

    assert_equal(:a, instance_1.a)
    assert_equal(:A, instance_2.a)
    assert_equal(:'@', instance_3.a)

    assert_equal('B', instance_1.b)
    assert_equal('B', instance_2.b)
    assert_equal('B', instance_3.b)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)
  end

  def test_build_new_instance_after_set_many_attributes
    instance_1 = Bar.new(a: nil, c: 'CC')
    instance_2 = instance_1.with_attributes(a: 'A', b: :bb)
    instance_3 = instance_1.with_attributes(a: '@', b: 'Bb')

    assert_equal({'a' => nil, 'b' => 'B', 'c'=>'CC'}, instance_1.attributes)
    assert_equal({'a' => 'A', 'b' => :bb, 'c'=>'CC'}, instance_2.attributes)
    assert_equal({'a' => '@', 'b' => 'Bb', 'c'=>'CC'}, instance_3.attributes)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)

    # ---

    instance_1 = Buz.new(a: 'A', c: 'CC')
    instance_2 = instance_1.with_attributes(a: 'A', b: :bb)
    instance_3 = instance_1.with_attributes(a: '@', b: 'Bb')

    assert_equal({'a' => :A, 'b' => 'B', 'c'=>'CC'}, instance_1.attributes)
    assert_equal({'a' => :A, 'b' => :bb, 'c'=>'CC'}, instance_2.attributes)
    assert_equal({'a' => :'@', 'b' => 'Bb', 'c'=>'CC'}, instance_3.attributes)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)
  end
end
