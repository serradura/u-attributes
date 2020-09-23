require 'test_helper'

class Micro::Attributes::Features::KeysAsSymbolTest < Minitest::Test
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

  def test_valid_attribute_definition
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

  def test_invalid_attribute_definition
    assert_instance_of(Kind::Error, @@__invalid_attribute_key)

    assert_equal('"only_symbol" expected to be a kind of Symbol', @@__invalid_attribute_key.message)
  end

  class Biz
    include Micro::Attributes.with(:initialize, :keys_as_symbol, :diff)

    attributes :a, :b, required: true
  end

  def test_the_impact_in_the_diff_extension
    biz1 = Biz.new(a: 1, b: 2)
    biz2 = biz1.with_attribute(:a, 2)

    diff = biz1.diff_attributes(biz2)

    # --

    assert_same(biz1, diff.from)
    assert_same(biz2, diff.to)

    # --

    assert_equal({a: {from: 1, to: 2}}, diff.differences)
    assert_predicate(diff.differences, :frozen?)

    # --

    refute_predicate(diff, :empty?)
    refute_predicate(diff, :blank?)
    assert_predicate(diff, :present?)

    # --

    assert diff.changed?
    assert diff.changed?(:a)
    assert diff.changed?(:a, from: 1, to: 2)

    refute diff.changed?('a')

    err2 = assert_raises(ArgumentError) { diff.changed?(from: 2, to: -2) }
    assert_equal('pass the attribute name with the :from and :to values', err2.message)

    # ---

    err = assert_raises(ArgumentError) { Biz.new(a: false) }
    assert_equal('missing keyword: :b', err.message)
  end

  class AttributesVisibility
    include Micro::Attributes.with(:keys_as_symbol)

    attribute :a
    attribute :b, private: true
    attribute :c, protected: true

    attributes :a1, :a2
    attributes :b1, :b2, private: true
    attributes :c1, :c2, protected: true

    def initialize(data)
      self.attributes = data
    end
  end

  def test_the_attributes_visibility
    a, a1, a2 = 'a', 'a1', 'a2'
    b, b1, b2 = 'b', 'b1', 'b2'
    c, c1, c2 = 'c', 'c1', 'c2'

    obj = AttributesVisibility.new(
      a: a, a1: a1, a2: a2,
      b: b, b1: b1, b2: b2,
      c: c, c1: c1, c2: c2
    )

    # --

    assert_equal(
      [:a, :b, :c, :a1, :a2, :b1, :b2, :c1, :c2],
      AttributesVisibility.attributes
    )

    assert_equal(
      [:a, :b, :c, :a1, :a2, :b1, :b2, :c1, :c2],
      obj.defined_attributes
    )

    # --

    assert_equal({
      public: [:a, :a1, :a2],
      private: [:b, :b1, :b2],
      protected: [:c, :c1, :c2]
    },
      AttributesVisibility.attributes_by_visibility
    )

    assert_equal({a: 'a', a1: 'a1', a2: 'a2'}, obj.attributes)

    assert_equal({
      public: [:a, :a1, :a2],
      private: [:b, :b1, :b2],
      protected: [:c, :c1, :c2]
    },
      obj.defined_attributes(:by_visibility)
    )

    # --

    [
      :bar, :foo
    ].each { |key| refute obj.attribute?(key) }

    [
      :a, :a1, :a2
    ].each { |key| assert obj.attribute?(key) }

    [
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| refute obj.attribute?(key) }

    [
      :a, :a1, :a2, :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert obj.attribute?(key, true) }

    [
      :bar, :foo
    ].each { |key| refute obj.attribute?(key, true) }

    # --

    [
      :a, :a1, :a2
    ].each { |key| assert_equal(key.to_s, obj.attribute(key)) }

    [
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert_nil(obj.attribute(key)) }

    # --

    [
      :b, :b1, :b2, :c, :c1, :c2,
    ].each do |key|
      err = assert_raises(NameError) { obj.attribute!(key) }

      assert_equal("tried to access a private attribute `#{key}", err.message)
    end

    [
      :bar, :foo
    ].each do |key|
      err = assert_raises(NameError) { obj.attribute!(key) }

      assert_equal("undefined attribute `#{key}", err.message)
    end

    # --

    [
      -> { obj.a }, -> { obj.a1 }, -> { obj.a2 }
    ].each { |fn| assert_match(/\Aa[12]?\z/, fn.call) }

    [
      -> { obj.b }, -> { obj.b1 }, -> { obj.b2 }
    ].each do |fn|
      assert_match(
        /private method `b[12]?' called for #<.+Test::AttributesVisibility/,
        assert_raises(NoMethodError, &fn).message
      )
    end

    [
      -> { obj.c }, -> { obj.c1 }, -> { obj.c2 }
    ].each do |fn|
      assert_match(
        /protected method `c[12]?' called for #<.+Test::AttributesVisibility/,
        assert_raises(NoMethodError, &fn).message
      )
    end
  end
end
