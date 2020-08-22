require 'test_helper'

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
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute 'b'
  end

  def test_single_definitions
    bar1 = Bar.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    bar2 = Bar.new(a: false)

    assert_equal false, bar2.a
  end

  class Bar2
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute 'b', required: true
  end

  def test_bar2_attributes_assignment
    bar1 = Bar2.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    err = assert_raises(ArgumentError) { Bar2.new(a: false) }
    assert_equal('missing keyword: :b', err.message)
  end

  class Bar3
    include Micro::Attributes.with(:initialize)

    attribute :a, required: true
    attribute 'b', required: true
  end

  def test_bar2_attributes_assignment
    bar1 = Bar3.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    err1 = assert_raises(ArgumentError) { Bar3.new(a: false) }
    assert_equal('missing keyword: :b', err1.message)

    err2 = assert_raises(ArgumentError) { Bar3.new({}) }
    assert_equal('missing keywords: :a, :b', err2.message)
  end

  # ---

  class FalseValue
    def self.call
      false
    end
  end

  class Baz
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute :b, default: FalseValue
    attribute 'c', default: -> { 'C' }
  end

  def test_single_definitions_with_default_values
    object = Baz.new(a: 'a')

    assert_equal 'a', object.a
    assert_equal false, object.b
    assert_equal 'C', object.c
  end

  # ---

  class Foo
    include Micro::Attributes.with(:initialize)

    attributes :a, 'b'
  end

  def test_multiple_definitions
    object = Foo.new(a: 'a', b: 'b')

    assert_equal 'a', object.a
    assert_equal 'b', object.b
  end

  # ---

  class Foz
    include Micro::Attributes.with(:initialize)

    attribute :a, default: -> value { value.to_s }
    attribute :b, default: proc { '_b' }
    attribute 'c', default: 'c_'
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
    foz = Foz.new(a: :a)

    assert_equal({'a'=>'a', 'b'=>nil}, bar.attributes)
    assert_equal({'a'=>'a', 'b'=>nil}, foo.attributes)
    assert_equal({'b'=>false, 'c'=>'C', 'a'=>'a'}, baz.attributes)
    assert_equal({'b'=>'_b', 'c'=>'c_', 'a'=>'a'}, foz.attributes)

    assert(bar.attributes.frozen?)
    assert(foo.attributes.frozen?)
    assert(baz.attributes.frozen?)
    assert(foz.attributes.frozen?)
  end

  def test_the_slicing_of_the_instance_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert_equal({a: 'a'}, bar.attributes(:a))
    assert_equal({'a'=>'a', 'b'=>nil}, foo.attributes('a', 'b'))
    assert_equal({'b'=>false, 'c'=>'C'}, baz.attributes('b', 'c'))
    assert_equal({b: '_b', c: 'c_', a: 'a'}, foz.attributes(:b, :c, :a))
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
      assert_equal('a', instance.attribute(:a))
      assert_equal('a', instance.attribute('a'))

      assert_nil(instance.attribute(:b))
      assert_nil(instance.attribute('b'))

      assert_nil(instance.attribute(:unknown))
      assert_nil(instance.attribute('unknown'))

      #
      # #attribute!
      #
      assert_equal('a', instance.attribute!(:a))
      assert_equal('a', instance.attribute!('a'))

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

  begin
    class InvalidAttributesDefinition
      include Micro::Attributes

      attributes foo: :bar
    end
  rescue => err
    @@__invalid_attributes_definition = err
  end

  def test_invalid_attributes_definition
    assert_instance_of(Kind::Error, @@__invalid_attributes_definition)

    assert_equal('{:foo=>:bar} expected to be a kind of String/Symbol', @@__invalid_attributes_definition.message)
  end
end
