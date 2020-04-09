require 'test_helper'

class Micro::Attributes::InheritanceTest < Minitest::Test
  class Base
    include Micro::Attributes.to_initialize

    attributes :e, f: { default: 'ƒ' }
  end

  class AnotherClassWithAttributes
    include Micro::Attributes
  end

  def test_base_classes_cant_access_the_methods_to_override_attributes_data
    [Base, AnotherClassWithAttributes].each do |klass|
      refute klass.respond_to?(:attribute!, true)
      refute klass.respond_to?(:attributes!, true)
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
    attribute! :f, { default: 'F' }
  end

  class SubSub2 < Sub
    attribute! :h
    attribute! :i, default: -99
    attributes! e: { default: '3' }, f: { default: '_F_' }, g: { default: 99 }
  end

  def test_overriding_default_attributes_data_with_subclasses
    assert_equal(['e', 'f'], SubSub.attributes)
    assert_equal(['e', 'f', 'h', 'i', 'g'], SubSub2.attributes)

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
