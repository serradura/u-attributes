require 'test_helper'

class Micro::Attributes::Features::AttributesKeysIndifferentTest < Minitest::Test
  class Bar
    include Micro::Attributes.with(:keys_as_symbol)

    attribute :a
    attribute :b
    attributes :c, :d

    def initialize(data)
      self.attributes = data
    end

    def a_plus_b
      a + b
    end
  end

  def test_if_the_attributes_keys_are_symbols
    bar = Bar.new(a: 1, b: 2, c: 3, d: 4)

    # --

    assert_equal(1, bar.a)
    assert_equal(2, bar.b)
    assert_equal(3, bar.c)
    assert_equal(4, bar.d)
    assert_equal(3, bar.a_plus_b)

    # --

    assert_equal({a: 1, b: 2, c: 3, d: 4}, bar.attributes)

    assert_equal({a: 1, a_plus_b: 3}, bar.attributes(:a, with: :a_plus_b))
    assert_equal({a: 1, b: 2, a_plus_b: 3}, bar.attributes(:a, :b, with: :a_plus_b))
    assert_equal({a: 1, b: 2, a_plus_b: 3}, bar.attributes([:a, :b], with: :a_plus_b))
    assert_equal({a: 1, b: 2, a_plus_b: 3}, bar.attributes(with: :a_plus_b, without: [:c, :d]))
    assert_equal({a: 1, b: 2, c: 3, a_plus_b: 3}, bar.attributes(with: :a_plus_b, without: :d))
    assert_equal({a: 1, b: 2, c: 3, d: 4, a_plus_b: 3}, bar.attributes(with: :a_plus_b))

    # --

    refute bar.attribute?('a')
    assert bar.attribute?(:a)

    # --

    assert_nil(bar.attribute('a'))
    assert_equal(1, bar.attribute(:a))

    # --

    incr1 = 0

    bar.attribute(:a) { |value| incr1 += value }
    bar.attribute('a') { |value| incr1 += value }
    bar.attribute(:foo) { |value| incr1 += value }
    bar.attribute('foo') { |value| incr1 += value }

    assert_equal(1, incr1)

    # --

    incr2 = 0

    bar.attribute!(:b) { |value| incr2 += value }

    assert_equal(2, incr2)

    err1 = assert_raises(NameError) { bar.attribute!('a') }
    assert_equal('undefined attribute `a', err1.message)

    err2 = assert_raises(NameError) { bar.attribute!('foo') }
    assert_equal('undefined attribute `foo', err2.message)

    err3 = assert_raises(NameError) { bar.attribute!(:foo) }
    assert_equal('undefined attribute `foo', err3.message)

    # --

    assert_equal(
      { a: nil, b: nil, c: nil, d: nil },
      Bar.new('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4).attributes
    )
  end

  class Foo
    include Micro::Attributes.with(:initialize, :keys_as_symbol)

    attributes :a, :b
  end

  def test_the_behavior_composing_keys_as_symbol_with_initialize
    foo1 = Foo.new(a: 5, b: 5)
    foo2 = foo1.with_attribute(:a, 1)
    foo3 = foo1.with_attribute('a', 1)

    assert_equal({a: 5, b: 5}, foo1.attributes)
    assert_equal({a: 1, b: 5}, foo2.attributes)
    assert_equal({a: 5, b: 5}, foo3.attributes)

    refute_same(foo1, foo2)
    refute_same(foo1, foo3)

    foo4 = foo1.with_attributes(a: 1, b:1)
    foo5 = foo1.with_attributes('a' => 1, 'b' => 1)

    assert_equal({a: 1, b: 1}, foo4.attributes)
    assert_equal({a: 5, b: 5}, foo5.attributes)

    refute_same(foo1, foo4)
    refute_same(foo1, foo5)
  end

  class Foz
    include Micro::Attributes.with(:keys_as_symbol)

    attribute :a, default: 1
    attribute :b, default: -> value { value * 2 }

    def initialize(data)
      self.attributes = data
    end
  end

  def test_attributes_default_values
    foz = Foz.new(b: 3)

    assert_equal({a: 1, b: 6}, foz.attributes)
  end

  def test_the_attributes_access
    [Bar, Foo, Foz].each do |klass|
      assert_equal(:symbol, klass.attributes_access)
    end
  end

  begin
    class Baz
      include Micro::Attributes.with(:keys_as_symbol)

      attribute 'only_symbol'
    end
  rescue => e
    @@__invalid_attribute_key = e
  end

  def test_the_attributes_access
    assert_instance_of(Kind::Error, @@__invalid_attribute_key)
    assert_equal('"only_symbol" expected to be a kind of Symbol', @@__invalid_attribute_key.message)
  end
end
