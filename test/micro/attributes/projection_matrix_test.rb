require 'test_helper'

# `#attributes(*names, keys_as:, with:, without:)` projection options
# behave subtly differently depending on whether KeysAsSymbol is on.
# Pin every combination down under both key modes.
class Micro::Attributes::ProjectionMatrixTest < Minitest::Test
  class StringKeyed
    include Micro::Attributes.with(:initialize)

    attribute :first_name, default: 'John'
    attribute :last_name,  default: 'Doe'
    attribute :secret,     default: 'sssh', private: true

    def full_name
      "#{first_name} #{last_name}"
    end

    private def reveal
      secret
    end
  end

  class SymbolKeyed
    include Micro::Attributes.with(:initialize, :keys_as_symbol)

    attribute :first_name, default: 'John'
    attribute :last_name,  default: 'Doe'
    attribute :secret,     default: 'sssh', private: true

    def full_name
      "#{first_name} #{last_name}"
    end

    private def reveal
      secret
    end
  end

  KEY_MODES = [
    { label: 'string', klass: StringKeyed, key: ->(name) { name.to_s } },
    { label: 'symbol', klass: SymbolKeyed, key: ->(name) { name.to_sym } },
  ].freeze

  def each_mode
    KEY_MODES.each { |mode| yield(mode) }
  end

  # ---------- baseline: #attributes returns all public attrs -----------

  def test_attributes_returns_all_public_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})

      assert_equal(2, obj.attributes.size, mode[:label])
      assert(obj.attributes.key?(mode[:key].call(:first_name)), mode[:label])
      assert(obj.attributes.key?(mode[:key].call(:last_name)),  mode[:label])
      refute(obj.attributes.key?(mode[:key].call(:secret)),     'private excluded')
    end
  end

  # ---------- positional name filter -----------------------------------
  # NOTE: when positional names are used without `keys_as:`, the result keys
  # are preserved AS-PASSED (the implementation uses indifferent lookup for
  # the values but doesn't transform the keys). This is the documented
  # behavior in `test_the_slicing_options`.

  def test_attributes_with_single_positional_symbol_name_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(:first_name)

      assert_equal({first_name: 'John'}, result, mode[:label])
    end
  end

  def test_attributes_with_multiple_positional_symbol_names_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(:first_name, :last_name)

      assert_equal({first_name: 'John', last_name: 'Doe'}, result, mode[:label])
    end
  end

  def test_attributes_with_array_of_symbol_names_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes([:first_name, :last_name])

      assert_equal({first_name: 'John', last_name: 'Doe'}, result, mode[:label])
    end
  end

  def test_attributes_with_positional_string_names_indifferent_only_in_string_mode
    obj = StringKeyed.new({})

    # String-keyed mode: indifferent — string names look up the string-stored attributes.
    assert_equal({'first_name' => 'John', 'last_name' => 'Doe'}, obj.attributes('first_name', 'last_name'))
    assert_equal({'first_name' => 'John'}, obj.attributes(['first_name']))

    # Symbol-keyed mode (KeysAsSymbol): string names don't resolve.
    sym_obj = SymbolKeyed.new({})
    assert_equal({}, sym_obj.attributes('first_name'), 'symbol mode: string name silently dropped')
  end

  # ---------- keys_as: coercion ----------------------------------------

  def test_attributes_keys_as_symbol_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(keys_as: Symbol)

      assert_equal({first_name: 'John', last_name: 'Doe'}, result, mode[:label])
    end
  end

  def test_attributes_keys_as_string_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(keys_as: String)

      assert_equal({'first_name' => 'John', 'last_name' => 'Doe'}, result, mode[:label])
    end
  end

  def test_attributes_keys_as_symbol_with_positional_filter
    each_mode do |mode|
      obj = mode[:klass].new({})

      assert_equal({first_name: 'John'}, obj.attributes(:first_name, keys_as: Symbol), mode[:label])
      assert_equal({last_name: 'Doe'},   obj.attributes([:last_name],  keys_as: Symbol), mode[:label])
    end
  end

  def test_attributes_keys_as_string_with_positional_filter
    # `keys_as:` runs AFTER lookup, so the positional name still has to
    # resolve in the class's native key mode (symbol-only under KeysAsSymbol).
    each_mode do |mode|
      obj = mode[:klass].new({})

      assert_equal({'first_name' => 'John'}, obj.attributes(:first_name, keys_as: String), mode[:label])
    end

    # String mode is indifferent — string positional names also resolve.
    assert_equal({'last_name' => 'Doe'}, StringKeyed.new({}).attributes(['last_name'], keys_as: String))
    # Symbol mode: string positional names don't resolve, so the result is empty.
    assert_equal({}, SymbolKeyed.new({}).attributes(['last_name'], keys_as: String))
  end

  def test_attributes_keys_as_short_form
    # `:symbol` / `:string` aliases for the class forms
    each_mode do |mode|
      obj = mode[:klass].new({})
      assert_equal({first_name: 'John', last_name: 'Doe'}, obj.attributes(keys_as: :symbol), mode[:label])
      assert_equal({'first_name' => 'John', 'last_name' => 'Doe'}, obj.attributes(keys_as: :string), mode[:label])
    end
  end

  # ---------- without: option ------------------------------------------

  def test_attributes_without_single_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})

      result = obj.attributes(without: :last_name)
      refute(result.key?(mode[:key].call(:last_name)), mode[:label])
      assert(result.key?(mode[:key].call(:first_name)), mode[:label])
    end
  end

  def test_attributes_without_array_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      assert_equal({}, obj.attributes(without: [:first_name, :last_name]), mode[:label])
    end
  end

  # ---------- with: option (extra method-derived values) ---------------

  def test_attributes_with_extra_method_value
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(with: :full_name)

      assert_equal('John Doe', result[mode[:key].call(:full_name)], mode[:label])
      # Original attrs still present
      assert(result.key?(mode[:key].call(:first_name)), mode[:label])
      assert(result.key?(mode[:key].call(:last_name)),  mode[:label])
    end
  end

  def test_attributes_with_filter_and_extra
    # Positional filter keys are kept as-passed; `with:` extras follow the class's key mode.
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(:first_name, with: :full_name)

      assert_equal(2, result.size, mode[:label])
      assert_equal('John',     result[:first_name], mode[:label])
      assert_equal('John Doe', result[mode[:key].call(:full_name)],  mode[:label])
    end
  end

  def test_attributes_with_extra_and_without
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(with: :full_name, without: :last_name)

      assert_equal(2, result.size, mode[:label])
      assert_equal('John',     result[mode[:key].call(:first_name)], mode[:label])
      assert_equal('John Doe', result[mode[:key].call(:full_name)],  mode[:label])
    end
  end

  # ---------- with: + keys_as: -----------------------------------------

  def test_attributes_with_extra_and_keys_as_symbol
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(with: :full_name, keys_as: Symbol)

      assert_equal({first_name: 'John', last_name: 'Doe', full_name: 'John Doe'}, result, mode[:label])
    end
  end

  def test_attributes_with_extra_and_keys_as_string
    each_mode do |mode|
      obj = mode[:klass].new({})
      result = obj.attributes(with: :full_name, keys_as: String)

      assert_equal({'first_name' => 'John', 'last_name' => 'Doe', 'full_name' => 'John Doe'}, result, mode[:label])
    end
  end

  # ---------- private/protected exclusion ------------------------------

  def test_attributes_excludes_private_even_with_keys_as_or_without
    # Private attribute should never appear in `#attributes` output,
    # regardless of projection options or key mode.
    each_mode do |mode|
      obj = mode[:klass].new({})

      [
        obj.attributes,
        obj.attributes(keys_as: String),
        obj.attributes(keys_as: Symbol),
        obj.attributes(:first_name, :last_name),
        obj.attributes(with: :full_name),
        obj.attributes(without: :first_name),
      ].each do |result|
        refute(result.key?('secret'),  "no secret string key (#{mode[:label]})")
        refute(result.key?(:secret),   "no secret symbol key (#{mode[:label]})")
      end
    end
  end

  # ---------- indifferent vs strict access -----------------------------
  # Default mode allows query by either symbol or string;
  # KeysAsSymbol only by symbol.

  def test_attribute_access_string_mode_is_indifferent
    obj = StringKeyed.new({})

    assert_equal('John', obj.attribute(:first_name))
    assert_equal('John', obj.attribute('first_name'))

    assert(obj.attribute?(:first_name))
    assert(obj.attribute?('first_name'))
  end

  def test_attribute_access_symbol_mode_is_strict
    obj = SymbolKeyed.new({})

    assert_equal('John', obj.attribute(:first_name))
    assert_nil(obj.attribute('first_name'))

    assert(obj.attribute?(:first_name))
    refute(obj.attribute?('first_name'))

    err = assert_raises(NameError) { obj.attribute!('first_name') }
    assert_match(/undefined attribute `first_name/, err.message)
  end

  # ---------- with attributes_access introspection ---------------------

  def test_class_level_attributes_access_advertises_mode
    assert_equal(:indifferent, StringKeyed.attributes_access)
    assert_equal(:symbol,      SymbolKeyed.attributes_access)
  end

  def test_defined_attributes_by_visibility_under_both_modes
    each_mode do |mode|
      obj = mode[:klass].new({})
      by_vis = obj.defined_attributes(:by_visibility)

      assert_includes(by_vis[:public],  mode[:key].call(:first_name), mode[:label])
      assert_includes(by_vis[:public],  mode[:key].call(:last_name),  mode[:label])
      assert_includes(by_vis[:private], mode[:key].call(:secret),     mode[:label])
      refute_includes(by_vis[:public],  mode[:key].call(:secret),     mode[:label])
    end
  end
end
