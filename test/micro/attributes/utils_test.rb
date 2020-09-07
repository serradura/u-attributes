require 'test_helper'

class Micro::Attributes::UtilsTest < Minitest::Test
  def test_stringify_hash_keys
    err = assert_raises(Kind::Error) { Micro::Attributes::Utils::Hashes.stringify_keys([]) }

    assert_equal('[] expected to be a kind of Hash', err.message)

    # --

    hash = { :a => 1 }

    new_hash = Micro::Attributes::Utils::Hashes.stringify_keys(hash)

    refute_same(hash, new_hash)
    assert_equal({ 'a'=> 1 }, new_hash)

    if hash.respond_to?(:transform_keys)
      def hash.respond_to?(method)
        method == :transform_keys ? false : super
      end

      new_hash = Micro::Attributes::Utils::Hashes.stringify_keys(hash)

      refute_same(hash, new_hash)
      assert_equal({ 'a' => 1 }, new_hash)
    end
  end

  def test_symbolize_hash_keys
    err = assert_raises(Kind::Error) { Micro::Attributes::Utils::Hashes.symbolize_keys([]) }

    assert_equal('[] expected to be a kind of Hash', err.message)

    # --

    hash = { 'a' => 1 }

    new_hash = Micro::Attributes::Utils::Hashes.symbolize_keys(hash)

    refute_same(hash, new_hash)
    assert_equal({ :a => 1 }, new_hash)

    if hash.respond_to?(:transform_keys)
      def hash.respond_to?(method)
        method == :transform_keys ? false : super
      end

      new_hash = Micro::Attributes::Utils::Hashes.symbolize_keys(hash)

      refute_same(hash, new_hash)
      assert_equal({ :a => 1 }, new_hash)
    end
  end

  def test_the_transformation_of_hash_keys
    err1 = assert_raises(Kind::Error) { Micro::Attributes::Utils::Hashes.keys_as(nil, []) }

    assert_equal('[] expected to be a kind of Hash', err1.message)

    # --

    err2 = assert_raises(Kind::Error) { Micro::Attributes::Utils::Hashes.keys_as(Symbol, []) }
    err3 = assert_raises(Kind::Error) { Micro::Attributes::Utils::Hashes.keys_as(String, []) }

    assert_equal('[] expected to be a kind of Hash', err2.message)
    assert_equal('[] expected to be a kind of Hash', err3.message)

    # --

    hash1 = { :a => 1 }
    hash2 = { 'a' => 1 }

    err4 = assert_raises(ArgumentError) { Micro::Attributes::Utils::Hashes.keys_as(Hash, hash1) }
    err5 = assert_raises(ArgumentError) { Micro::Attributes::Utils::Hashes.keys_as(Array, hash2) }

    assert_equal('first argument must be the class String or Symbol', err4.message)
    assert_equal('first argument must be the class String or Symbol', err5.message)

    # --

    assert_equal({:a => 1}, Micro::Attributes::Utils::Hashes.keys_as(Symbol, hash1))
    assert_equal({:a => 1}, Micro::Attributes::Utils::Hashes.keys_as(Symbol, hash2))

    assert_equal({'a' => 1}, Micro::Attributes::Utils::Hashes.keys_as(String, hash1))
    assert_equal({'a' => 1}, Micro::Attributes::Utils::Hashes.keys_as(String, hash2))
  end

  def test_allow_hash_access_with_string_or_symbol_keys
    hash = { :symbol => 'symbol', 'string' => 'string', false: false }

    assert_equal('symbol', Micro::Attributes::Utils::Hashes.get(hash, 'symbol'))
    assert_equal('symbol', Micro::Attributes::Utils::Hashes.get(hash, :symbol))
    assert_equal('string', Micro::Attributes::Utils::Hashes.get(hash, 'string'))
    assert_equal('string', Micro::Attributes::Utils::Hashes.get(hash, :string))
    assert_equal(false, Micro::Attributes::Utils::Hashes.get(hash, 'false'))
    assert_equal(false, Micro::Attributes::Utils::Hashes.get(hash, :false))
    assert_nil(Micro::Attributes::Utils::Hashes.get(hash, 'not_here'))
    assert_nil(Micro::Attributes::Utils::Hashes.get(hash, :not_here))
  end
end
