require 'test_helper'

class Micro::Attributes::Features::DiffTest < Minitest::Test
  class Foo
    include Micro::Attributes.to_initialize(diff: true)

    attribute :a
    attribute 'b'
  end

  class Bar
    include Micro::Attributes::With::DiffAndInitialize

    attributes :a, 'b'
  end

  def setup
    @foo_1 = Foo.new(a: 1, b: 2)
    @bar_1 = Bar.new(a: 3, b: 4)

    @foo_2 = @foo_1.with_attribute(:a, -1)
    @bar_2 = @bar_1.with_attributes(a: -3, b: -4)

    @foo_changes = @foo_1.diff_attributes(@foo_2)
    @bar_changes = @bar_1.diff_attributes(@bar_2)
  end

  def test_diff_attributes_error
    err1 = assert_raises(ArgumentError) { @foo_1.diff_attributes(nil) }
    assert_equal('nil must implement Micro::Attributes', err1.message)

    err2 = assert_raises(ArgumentError) { @foo_1.diff_attributes({}) }
    assert_equal('{} must implement Micro::Attributes', err2.message)

    err3 = assert_raises(ArgumentError) { @foo_1.diff_attributes(@bar_1) }
    assert_equal('expected an instance of Micro::Attributes::Features::DiffTest::Foo', err3.message)

    err4 = assert_raises(ArgumentError) { @bar_2.diff_attributes(@foo_2) }
    assert_equal('expected an instance of Micro::Attributes::Features::DiffTest::Bar', err4.message)
  end

  def test_from
    assert_same(@foo_1, @foo_changes.from)
    assert_same(@bar_1, @bar_changes.from)
  end

  def test_to
    assert_same(@foo_2, @foo_changes.to)
    assert_same(@bar_2, @bar_changes.to)
  end

  def test_differences
    assert_equal({}, @foo_1.diff_attributes(@foo_1).differences)
    assert_equal({}, @bar_1.diff_attributes(@bar_1).differences)

    assert_equal({'a' => {'from' => 1, 'to' => -1}}, @foo_changes.differences)
    assert_equal({'a' => {'from' => 3, 'to' => -3}, 'b' => {'from' => 4, 'to' => -4 }}, @bar_changes.differences)
    assert(@foo_changes.differences.frozen?)
    assert(@bar_changes.differences.frozen?)
  end

  def test_present?
    assert @foo_changes.present?
    assert @bar_changes.present?

    refute @foo_1.diff_attributes(@foo_1).present?
    refute @bar_1.diff_attributes(@bar_1).present?
  end

  def test_blank?
    refute @foo_changes.blank?
    refute @bar_changes.blank?

    assert @foo_1.diff_attributes(@foo_1).blank?
    assert @bar_1.diff_attributes(@bar_1).blank?
  end

  def test_empty?
    assert_equal(@foo_changes.method(:empty?), @foo_changes.method(:blank?))
    assert_equal(@bar_changes.method(:empty?), @bar_changes.method(:blank?))
  end

  def test_changed?
    assert @foo_changes.changed?
    assert @bar_changes.changed?

    refute @foo_1.diff_attributes(@foo_1).changed?
    refute @bar_1.diff_attributes(@bar_1).changed?
  end

  def test_changed_with_an_attribute_name
    refute @foo_changes.changed?('b')
    refute @foo_changes.changed?(:b)

    assert @bar_changes.changed?('b')
    assert @bar_changes.changed?(:b)
  end

  def test_changed_with_an_attribute_name_and_from_to
    refute @foo_changes.changed?('b', from: 2, to: -2)
    refute @foo_changes.changed?(:b, from: 2, to: -2)

    err1 = assert_raises(ArgumentError) { @foo_changes.changed?(from: 2, to: -2) }
    assert_equal('pass the attribute name with the :from and :to values', err1.message)

    assert @bar_changes.changed?('b', from: 4, to: -4)
    assert @bar_changes.changed?(:b, from: 4, to: -4)

    err2 = assert_raises(ArgumentError) { @bar_changes.changed?(from: 2, to: -2) }
    assert_equal('pass the attribute name with the :from and :to values', err2.message)
  end
end
