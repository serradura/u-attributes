require 'test_helper'

class Micro::Attributes::InheritanceTest < Minitest::Test
  class Base
    include Micro::Attributes.with(:initialize)

    attribute :e
    attribute :f, default: 'ƒ'
  end

  class AnotherClassWithAttributes
    include Micro::Attributes
  end

  def test_base_classes_cant_access_the_methods_to_override_attributes_data
    [Base, AnotherClassWithAttributes].each do |klass|
      refute klass.respond_to?(:attribute!, true)
    end
  end

  class Sub < Base
  end

  def test_the_inheritance_of_default_values
    assert_equal ['e', 'f'], Sub.attributes

    object = Sub.new(e: '£')

    assert_equal('£', object.e)
    assert_equal('ƒ', object.f)
  end

  class SubSub < Sub
    attribute! :f, default: 'F'
  end

  class SubSub2 < Sub
    attribute! :h
    attribute! :i, default: -99
    attribute! :e, default:'3'
    attribute! :f, default:'_F_'
    attribute! :g, default: 99
  end

  def test_overriding_default_attributes_data_with_subclasses
    assert_equal(['e', 'f'], SubSub.attributes)
    assert_equal(['e', 'f', 'h', 'i', 'g'], SubSub2.attributes)

    assert_equal(Sub.attributes, SubSub.attributes)
    refute_equal(Sub.attributes, SubSub2.attributes)

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

  class BaseFrozenAttributes
    include Micro::Attributes

    attributes :a
    attributes :b, freeze: true
    attributes :c, freeze: :after_dup
    attributes :d, freeze: :after_clone

    attributes :a1, :a2
    attributes :b1, :b2, freeze: true
    attributes :c1, :c2, freeze: :after_dup
    attributes :d1, :d2, freeze: :after_clone

    def initialize(data)
      self.attributes = data
    end
  end

  class FrozenAttributes < BaseFrozenAttributes
  end

  def test_the_attributes_freezing_with_inheritance
    a, b, c, d = 'a', 'b', 'c', 'd'
    a1, a2 = 'a1', 'a2'
    b1, b2 = 'b1', 'b2'
    c1, c2 = 'c1', 'c2'
    d1, d2 = 'd1', 'd2'

    [c, d, c1, c2, d1, d2].each do |str|
      def str.foo; :foo; end
    end

    obj = FrozenAttributes.new(
      a: a, b: b, c: c, d: d,
      a1: a1, a2: a2,
      b1: b1, b2: b2,
      c1: c1, c2: c2,
      d1: d1, d2: d2
    )

    # --

    refute_predicate(a, :frozen?)
    refute_predicate(a1, :frozen?)
    refute_predicate(a2, :frozen?)

    assert_same(a, obj.a)
    assert_same(a1, obj.a1)
    assert_same(a2, obj.a2)

    # --

    assert_predicate(b, :frozen?)
    assert_predicate(b1, :frozen?)
    assert_predicate(b2, :frozen?)

    assert_same(b, obj.b)
    assert_same(b1, obj.b1)
    assert_same(b2, obj.b2)

    # --

    refute_predicate(c, :frozen?)
    refute_predicate(c1, :frozen?)
    refute_predicate(c2, :frozen?)

    refute_same(c, obj.c)
    refute_same(c1, obj.c1)
    refute_same(c2, obj.c2)

    assert_equal(c, obj.c)
    assert_equal(c1, obj.c1)
    assert_equal(c2, obj.c2)

    refute_respond_to(obj.c, :foo)
    refute_respond_to(obj.c1, :foo)
    refute_respond_to(obj.c2, :foo)

    # --

    refute_predicate(d, :frozen?)
    refute_predicate(d1, :frozen?)
    refute_predicate(d2, :frozen?)

    refute_same(d, obj.d)
    refute_same(d1, obj.d1)
    refute_same(d2, obj.d2)

    assert_equal(d, obj.d)
    assert_equal(d1, obj.d1)
    assert_equal(d2, obj.d2)

    assert_respond_to(obj.d, :foo)
    assert_respond_to(obj.d1, :foo)
    assert_respond_to(obj.d2, :foo)
  end

  class BaseAttributesVisibility
    include Micro::Attributes

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

  class AttributesVisibility < BaseAttributesVisibility
  end

  def test_the_attributes_visibility_with_inheritance
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
      ['a', 'b', 'c', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2'],
      AttributesVisibility.attributes
    )

    assert_equal(
      ['a', 'b', 'c', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2'],
      obj.defined_attributes
    )

    # --

    assert_equal({
      public: ['a', 'a1', 'a2'],
      private: ['b', 'b1', 'b2'],
      protected: ['c', 'c1', 'c2']
    },
      AttributesVisibility.attributes_by_visibility
    )

    assert_equal({'a' => 'a', 'a1' => 'a1', 'a2' => 'a2'}, obj.attributes)

    assert_equal({
      public: ['a', 'a1', 'a2'],
      private: ['b', 'b1', 'b2'],
      protected: ['c', 'c1', 'c2']
    },
      obj.defined_attributes(:by_visibility)
    )

    # --

    [
      'foo', 'bar', :bar, :foo
    ].each { |key| refute obj.attribute?(key) }

    [
      'a', 'a1', 'a2', :a, :a1, :a2
    ].each { |key| assert obj.attribute?(key) }

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| refute obj.attribute?(key) }

    [
      'a', 'a1', 'a2', 'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :a, :a1, :a2, :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert obj.attribute?(key, true) }

    [
      'foo', 'bar', :bar, :foo
    ].each { |key| refute obj.attribute?(key, true) }

    # --

    [
      'a', 'a1', 'a2', :a, :a1, :a2
    ].each { |key| assert_equal(key.to_s, obj.attribute(key)) }

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert_nil(obj.attribute(key)) }

    # --

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each do |key|
      err = assert_raises(NameError) { obj.attribute!(key) }

      assert_equal("tried to access a private attribute `#{key}", err.message)
    end

    [
      'foo', 'bar', :bar, :foo
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

  class BaseSignUpParams
    include Micro::Attributes.with(:accept, :initialize)

    TrimString = -> value { String(value).strip }

    attribute :email                , default: TrimString, accept: -> str { str =~ /\A.+@.+\..+\z/ }, freeze: :after_dup
    attribute :password             , default: TrimString, reject: :empty?, private: true
    attribute :password_confirmation, default: TrimString, reject: :empty?, private: true

    def valid_password?
      accepted_attributes? && password == password_confirmation
    end

    def password_digest
      Digest::SHA256.hexdigest(password) if valid_password?
    end
  end

  class SignUpParams < BaseSignUpParams
  end

  def test_visibility_and_accept_and_freeze_with_inheritance
    sign_up1 = SignUpParams.new(
      email: '         test@email.com          ',
      password: "\t         123456  \r",
      'password_confirmation' => "\n\r123456\t\n"
    )

    assert_equal('test@email.com', sign_up1.email)
    assert_equal(
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
      sign_up1.password_digest
    )

    assert_predicate(sign_up1.email, :frozen?)

    # --

    sign_up2 = SignUpParams.new(
      email: 'test@email.com',
      password: '123456',
      'password_confirmation' => '123457'
    )

    assert_nil(sign_up2.password_digest)

    assert_predicate(sign_up2.email, :frozen?)
  end
end
