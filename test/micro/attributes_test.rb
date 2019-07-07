require "test_helper"

class Micro::AttributesTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Micro::Attributes::VERSION
  end

  # ---

  class Biz
    include Micro::Attributes

    attribute :a
    attributes :b, :c

    def initialize(a, b, c='_c')
      @a, @b = a, b
      @c = c
    end
  end

  def test_custom_constructor
    object = Biz.new('a', nil)

    assert_equal('a', object.a)
    assert_equal('_c', object.c)
    assert_nil(object.b)
  end

  # ---

  class Bar
    include Micro::Attributes.to_initialize

    attribute :a
    attribute 'b'
  end

  def test_single_definitions
    object = Bar.new(a: 'a', b: 'b')

    assert_equal 'a', object.a
    assert_equal 'b', object.b
  end

  # ---

  class Baz
    include Micro::Attributes.to_initialize

    attribute :a
    attribute b: 'B'
    attribute 'c' => 'C'
  end

  def test_single_definition_with_default_values
    object = Baz.new(a: 'a')

    assert_equal 'a', object.a
    assert_equal 'B', object.b
    assert_equal 'C', object.c
  end

  # ---

  class Foo
    include Micro::Attributes.to_initialize

    attributes :a, 'b'
  end

  def test_multiple_definitions
    object = Foo.new(a: 'a', b: 'b')

    assert_equal 'a', object.a
    assert_equal 'b', object.b
  end

  # ---

  class Foz
    include Micro::Attributes.to_initialize

    attributes :a, b: '_b', 'c' => 'c_'
  end

  def test_multiple_definitions_with_default_values
    object = Foz.new(a: 'a')

    assert_equal 'a', object.a
    assert_equal '_b', object.b
    assert_equal 'c_', object.c
  end

  # ---

  def test_getting_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert_equal({"a"=>"a", "b"=>nil}, bar.attributes)
    assert_equal({"a"=>"a", "b"=>nil}, foo.attributes)
    assert_equal({"b"=>"B", "c"=>"C", "a"=>"a"}, baz.attributes)
    assert_equal({"b"=>"_b", "c"=>"c_", "a"=>"a"}, foz.attributes)
  end

  # ---

  def test_checking_attributes
    bar = Bar.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert bar.attribute?(:a)
    assert bar.attribute?('a')
    refute bar.attribute?('c')
    refute bar.attribute?(:c)

    assert foz.attribute?(:a)
    assert foz.attribute?('a')
    assert foz.attribute?('c')
    refute foz.attribute?(:d)
    refute foz.attribute?('d')

    assert Bar.attribute?(:a)
    assert Bar.attribute?('a')
    refute Bar.attribute?('c')
    refute Bar.attribute?(:c)

    assert Foz.attribute?(:a)
    assert Foz.attribute?('a')
    assert Foz.attribute?('c')
    refute Foz.attribute?(:d)
    refute Foz.attribute?('d')
  end

  # ---

  def test_the_constructor_argument_validation
    [Bar, Foo, Baz, Foz].each do |klass|
      error = assert_raises(ArgumentError) { klass.new(1) }
      assert_equal('argument must be a Hash', error.message)
    end
  end

  # ---

  def test_private_class_methods
    [Bar, Foo, Baz, Foz].each do |klass|
      assert klass.respond_to?(:__attribute, true)
      assert_raises(NoMethodError) { klass.__attribute }

      assert klass.respond_to?(:__attributes, true)
      assert_raises(NoMethodError) { klass.__attributes }

      assert klass.respond_to?(:__attribute_data, true)
      assert_raises(NoMethodError) { klass.__attribute_data }

      assert klass.respond_to?(:__attribute_data!, true)
      assert_raises(NoMethodError) { klass.__attribute_data! }

      assert klass.respond_to?(:__attributes_data, true)
      assert_raises(NoMethodError) { klass.__attributes_data }
    end
  end

  # ---

  def test_attributes_data
    [Bar, Foo, Baz, Foz].each do |klass|
      error = assert_raises(ArgumentError) { klass.attributes_data(1) }
      assert 'argument must be a Hash', error.message

      assert klass.attributes_data({}).is_a?(Hash)
      refute klass.attributes_data({}).empty?
    end
  end

  # ---

  def test_build_new_instance_after_set_one_attribute
    bar1 = Bar.new(a: 'a')
    bar2 = bar1.with_attribute(:a, 'A')
    bar3 = bar1.with_attribute(:a, '@')

    assert_equal('a', bar1.a)
    assert_equal('A', bar2.a)
    assert_equal('@', bar3.a)

    refute bar1 == bar2
    refute bar1 == bar3
  end

  # ---

  def test_build_new_instance_after_set_many_attributes
    baz1 = Baz.new(c: 'CC')
    baz2 = baz1.with_attributes(a: 'A', b: :bb)
    baz3 = baz1.with_attributes(a: '@', b: 'Bb')

    assert_equal({'a' => nil, 'b' => "B", "c"=>"CC"}, baz1.attributes)
    assert_equal({'a' => 'A', 'b' => :bb, "c"=>"CC"}, baz2.attributes)
    assert_equal({'a' => '@', 'b' => 'Bb', "c"=>"CC"}, baz3.attributes)

    refute_same baz1, baz2
    refute_same baz1, baz3
  end

  # ---

  class Base
    include Micro::Attributes.to_initialize

    attributes :e, f: 'ƒ'
  end

  def test_base_classes_cant_access_the_methods_to_override_attributes_data
    [Bar, Foo, Baz, Foz, Base].each do |klass|
      refute klass.respond_to?(:attribute!, true)
      refute klass.respond_to?(:attributes!, true)
    end
  end

  class Sub < Base
  end

  def test_inheritance
    assert_equal ['e', 'f'], Sub.attributes

    object = Sub.new(e: '£')

    assert_equal('£', object.e)
    assert_equal('ƒ', object.f)
  end

  class SubSub < Sub
    attribute! f: 'F'
  end

  class SubSub2 < Sub
    attributes! e: '3', f: '_F_', g: 99
    attribute! :h
    attribute! i: -99
  end

  def test_overriding_default_attributes_data_with_subclasses
    assert_equal(['e', 'f'], SubSub.attributes)
    assert_equal(['e', 'f', 'g', 'h', 'i'], SubSub2.attributes)

    assert_equal(Sub.attributes, SubSub.attributes)
    refute_equal(Sub.attributes, SubSub2.attributes)

    refute_equal(Sub.attributes_data({}), SubSub.attributes_data({}))
    refute_equal(SubSub.attributes_data({}), SubSub2.attributes_data({}))

    object1 = SubSub.new(e: 3)

    assert_equal(3, object1.e)
    assert_equal('F', object1.f)

    object2 = SubSub2.new({})

    assert_equal('3', object2.e)
    assert_equal('_F_', object2.f)
    assert_equal(99, object2.g)
    assert_nil(object2.h)
    assert_equal(-99, object2.i)
  end

  def test_the_argument_error_of_attributes!
    error = assert_raises(ArgumentError) { SubSub.attributes! }
    assert_equal('wrong number of arguments (given 0, expected 1 or more)', error.message)
  end
end
