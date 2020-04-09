require 'test_helper'

class Micro::Attributes::Features::InitializeTest < Minitest::Test
  class Foo
    include Micro::Attributes::With::Initialize

    attribute :a
    attribute 'b'
  end

  class Bar
    include Micro::Attributes.to_initialize(activemodel_validations: true)

    attribute :a
    attributes b: { default: 'B' }, 'c' => { default: 'C' }
  end

  class Buz
    include Micro::Attributes.to_initialize(diff: true)

    attributes :a, b: { default: 'B' }, 'c' => { default: 'C' }
  end

  def test_the_constructor_argument_validation
    [Foo, Bar].each do |klass|
      error = assert_raises(Kind::Error) { klass.new(1) }

      assert_equal('1 expected to be a kind of Hash', error.message)
    end
  end

  def test_build_new_instance_after_set_one_attribute
    instance_1 = Foo.new(a: 'a')
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

    assert_equal('a', instance_1.a)
    assert_equal('A', instance_2.a)
    assert_equal('@', instance_3.a)

    assert_equal('B', instance_1.b)
    assert_equal('B', instance_2.b)
    assert_equal('B', instance_3.b)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)
  end

  def test_build_new_instance_after_set_many_attributes
    instance_1 = Bar.new(c: 'CC')
    instance_2 = instance_1.with_attributes(a: 'A', b: :bb)
    instance_3 = instance_1.with_attributes(a: '@', b: 'Bb')

    assert_equal({'a' => nil, 'b' => 'B', 'c'=>'CC'}, instance_1.attributes)
    assert_equal({'a' => 'A', 'b' => :bb, 'c'=>'CC'}, instance_2.attributes)
    assert_equal({'a' => '@', 'b' => 'Bb', 'c'=>'CC'}, instance_3.attributes)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)

    # ---

    instance_1 = Buz.new(c: 'CC')
    instance_2 = instance_1.with_attributes(a: 'A', b: :bb)
    instance_3 = instance_1.with_attributes(a: '@', b: 'Bb')

    assert_equal({'a' => nil, 'b' => 'B', 'c'=>'CC'}, instance_1.attributes)
    assert_equal({'a' => 'A', 'b' => :bb, 'c'=>'CC'}, instance_2.attributes)
    assert_equal({'a' => '@', 'b' => 'Bb', 'c'=>'CC'}, instance_3.attributes)

    refute_same(instance_1, instance_2)
    refute_same(instance_1, instance_3)
  end
end
