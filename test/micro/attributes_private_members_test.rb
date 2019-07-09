require "test_helper"

class Micro::AttributesPrivateMembersTest < Minitest::Test
  class A
    include Micro::Attributes
  end

  class AA < A; end
  class AAA < AA; end

  class B
    include Micro::Attributes.to_initialize
  end

  class BB < B; end
  class BBB < BB; end

  class C
    include Micro::Attributes::ToInitialize
    include Micro::Attributes::Differ
  end

  class CC < C; end
  class CCC < CC; end

  def test_private_class_methods
    [A, AA, AAA, B, BB, BBB, C, CC, CCC].each do |klass|
      assert klass.respond_to?(:__attributes_data, true)
      assert_raises(NoMethodError) { klass.__attributes_data }

      assert klass.respond_to?(:__attributes, true)
      assert_raises(NoMethodError) { klass.__attributes }

      assert klass.respond_to?(:__attributes_def, true)
      assert_raises(NoMethodError) { klass.__attributes_def }

      assert klass.respond_to?(:__attributes_set, true)
      assert_raises(NoMethodError) { klass.__attributes_set }

      assert klass.respond_to?(:__attribute_reader, true)
      assert_raises(NoMethodError) { klass.__attribute_reader }

      assert klass.respond_to?(:__attribute_set, true)
      assert_raises(NoMethodError) { klass.__attribute_set }
    end
  end

  def test_private_constants
    [A, AA, AAA, B, BB, BBB, C, CC, CCC].each do |klass|
      refute klass.constants.include?(:Macros)
      assert klass.constants.include?(:AttributesUtils)
    end
  end
end
