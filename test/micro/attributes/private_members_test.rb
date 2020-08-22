require 'test_helper'

class Micro::Attributes::PrivateMembersTest < Minitest::Test
  class A
    include Micro::Attributes
  end

  class AA < A; end
  class AAA < AA; end

  class B
    include Micro::Attributes.with(:initialize)
  end

  class BB < B; end
  class BBB < BB; end

  class C
    include Micro::Attributes::With::Initialize
    include Micro::Attributes::Features::Diff
  end

  class CC < C; end
  class CCC < CC; end

  def test_private_class_methods
    [A, AA, AAA, B, BB, BBB, C, CC, CCC].each do |klass|
      assert klass.respond_to?(:__attributes, true)
      assert_raises(NoMethodError) { klass.__attributes }

      assert klass.respond_to?(:__attribute_reader, true)
      assert_raises(NoMethodError) { klass.__attribute_reader }

      assert klass.respond_to?(:__attribute_assign, true)
      assert_raises(NoMethodError) { klass.__attribute_assign }
    end
  end

  def test_private_constants
    [A, AA, AAA, B, BB, BBB, C, CC, CCC].each do |klass|
      refute klass.constants.include?(:Macros)
    end
  end
end
