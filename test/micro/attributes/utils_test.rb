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

  # --

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
