require 'test_helper'

class Micro::AttributesTest < Minitest::Test
  class Add < Micro::Case
    attributes 'a', :b

    def call!
      Success result: { number: a + b }
    end
  end

  def test_add
    result = Add.call(a: 1, 'b' => 2)

    assert_predicate result, :success?
    assert_equal 3, result[:number]
  end

  class Subtract1 < Micro::Case
    attribute :a, required: true
    attribute 'b', default: 1

    def call!
      Success result: { number: a - b }
    end
  end

  def test_subtract1
    err = assert_raises(ArgumentError) { Subtract1.call }
    assert_equal('missing keyword: :a', err.message )

    # --

    result1 = Subtract1.call(a: 3, b: 2)

    assert_predicate result1, :success?
    assert_equal 1, result1[:number]

    result2 = Subtract1.call(a: 3)

    assert_predicate result2, :success?
    assert_equal 2, result2[:number]
  end

  class Subtract2 < Micro::Case::Strict
    attribute :a
    attribute 'b', default: 2

    def call!
      Success result: { number: a - b }
    end
  end

  def test_subtract2
    err = assert_raises(ArgumentError) { Subtract2.call }
    assert_equal('missing keyword: :a', err.message )

    # --

    result1 = Subtract2.call(a: 3, b: 1)

    assert_predicate result1, :success?
    assert_equal 2, result1[:number]

    result2 = Subtract2.call(a: 3)

    assert_predicate result2, :success?
    assert_equal 1, result2[:number]
  end

  class Multiply1 < Micro::Case
    attribute :a, required: true
    attribute 'b', required: true

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply1
    err1 = assert_raises(ArgumentError) { Multiply1.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply1.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply1.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply2 < Micro::Case::Strict
    attribute :a
    attribute 'b'

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply2
    err1 = assert_raises(ArgumentError) { Multiply2.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply2.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply2.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply3 < Micro::Case::Strict
    attributes :a, 'b'

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply3
    err1 = assert_raises(ArgumentError) { Multiply3.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply3.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply3.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply4 < Multiply2
  end

  def test_multiply4
    err1 = assert_raises(ArgumentError) { Multiply4.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply4.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply4.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply5 < Multiply3
  end

  def test_multiply5
    err1 = assert_raises(ArgumentError) { Multiply5.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply5.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply5.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end
end
