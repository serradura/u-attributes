require "test_helper"

class Micro::AttributesTest < Minitest::Test
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
    attribute :b, 'B'
    attribute 'c', 'C'
  end

  def test_single_definitions_with_default_values
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

  def test_instance_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert_equal({"a"=>"a", "b"=>nil}, bar.attributes)
    assert_equal({"a"=>"a", "b"=>nil}, foo.attributes)
    assert_equal({"b"=>"B", "c"=>"C", "a"=>"a"}, baz.attributes)
    assert_equal({"b"=>"_b", "c"=>"c_", "a"=>"a"}, foz.attributes)

    assert(bar.attributes.frozen?)
    assert(foo.attributes.frozen?)
    assert(baz.attributes.frozen?)
    assert(foz.attributes.frozen?)
  end

  # ---

  def test_attribute?
    #
    # Classes
    #
    assert Bar.attribute?(:a)
    assert Bar.attribute?('a')
    refute Bar.attribute?('c')
    refute Bar.attribute?(:c)

    assert Foz.attribute?(:a)
    assert Foz.attribute?('a')
    assert Foz.attribute?('c')
    refute Foz.attribute?(:d)
    refute Foz.attribute?('d')

    #
    # Instances
    #
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
  end

  # ---

  def test_instance_attribute
    [Biz.new('a', nil), Bar.new(a: 'a')].each do |instance|
      #
      # #attribute
      #
      assert_equal("a", instance.attribute(:a))
      assert_equal("a", instance.attribute('a'))

      assert_nil(instance.attribute(:b))
      assert_nil(instance.attribute('b'))

      assert_nil(instance.attribute(:unknown))
      assert_nil(instance.attribute('unknown'))

      #
      # #attribute!
      #
      assert_equal("a", instance.attribute!(:a))
      assert_equal("a", instance.attribute!('a'))

      assert_nil(instance.attribute!(:b))
      assert_nil(instance.attribute!('b'))

      err1 = assert_raises(NameError) { instance.attribute!(:unknown) }
      assert_equal('undefined attribute `unknown', err1.message)

      err2 = assert_raises(NameError) { instance.attribute!('unknown') }
      assert_equal('undefined attribute `unknown', err2.message)
    end
  end

  def test_instance_attribute_with_a_block
    [Biz.new('a', nil), Bar.new(a: 'a')].each do |instance|
      #
      # #attribute
      #
      acc1 = 0
      instance.attribute(:a) { |val| acc1 += 1 if val == 'a' }
      instance.attribute('a') { |val| acc1 += 1 if val == 'a' }
      assert_equal(2, acc1)

      instance.attribute(:b) { |val| acc1 += 1 if val.nil? }
      instance.attribute('b') { |val| acc1 += 1 if val.nil? }
      assert_equal(4, acc1)

      instance.attribute(:unknown) { |_val| acc1 += 1 }
      instance.attribute('unknown') { |_val| acc1 += 1 }
      assert_equal(4, acc1)

      #
      # #attribute!
      #
      acc2 = 0
      instance.attribute(:a) { |val| acc2 += 1 if val == 'a' }
      instance.attribute('a') { |val| acc2 += 1 if val == 'a' }
      assert_equal(2, acc2)

      instance.attribute(:b) { |val| acc2 += 1 if val.nil? }
      instance.attribute('b') { |val| acc2 += 1 if val.nil? }
      assert_equal(4, acc2)

      err1 = assert_raises(NameError) do
        instance.attribute!(:unknown) { |_val| acc2 += 1 }
      end
      assert_equal('undefined attribute `unknown', err1.message)

      err2 = assert_raises(NameError) do
        instance.attribute!('unknown') { |_val| acc2 += 1 }
      end
      assert_equal('undefined attribute `unknown', err2.message)
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
end
