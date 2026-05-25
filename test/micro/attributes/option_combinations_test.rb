require 'test_helper'

# Cross-product tests for per-attribute options that should hold consistent
# meaning regardless of which feature combination is enabled via
# `Micro::Attributes.with(...)`. The existing test files cover each option
# in one or two contexts; this file pins each one down across every
# meaningful feature combination so a regression in any cell is caught.
#
# Axes that interact with these options:
#   - init:   none / :initialize / `initialize: :strict`
#   - accept: none / :accept     / `accept: :strict`
#   - keys:   string / `:keys_as_symbol`
#
# (diff and activemodel_validations don't affect per-attribute option
# semantics, so they're not part of these cells.)
class Micro::Attributes::OptionCombinationsTest < Minitest::Test
  INIT_OPTIONS   = [:none, :base, :strict].freeze
  ACCEPT_OPTIONS = [:none, :base, :strict].freeze
  KEYS_OPTIONS   = [false, true].freeze

  def self.build_args(init, accept, keys)
    args = []
    extra = {}
    args << :initialize if init == :base
    args << :accept if accept == :base
    args << :keys_as_symbol if keys
    extra[:initialize] = :strict if init == :strict
    extra[:accept] = :strict if accept == :strict
    args << extra unless extra.empty?
    args
  end

  def self.label(init, accept, keys)
    ["init_#{init}", "accept_#{accept}", keys ? 'keys_sym' : 'keys_str'].join('_')
  end

  # Build a class and attach an `attribute_block` proc that the test
  # body uses to add attributes to it. Centralizes the boilerplate of
  # picking the right `with(...)` and adding a custom init when needed.
  def self.cell_klass(init, accept, keys, &attribute_block)
    args = build_args(init, accept, keys)

    # When no features are requested, fall back to including bare
    # Micro::Attributes (the "all-none" cell would otherwise call
    # `.with()` with no args, which is — correctly — an error).
    mod = args.empty? ? ::Micro::Attributes : ::Micro::Attributes.with(*args)

    klass = Class.new
    klass.send(:include, mod)

    if init == :none
      klass.class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def initialize(arg); self.attributes = arg; end
      RUBY
    end

    klass.class_eval(&attribute_block)
    klass
  end

  def self.cells
    INIT_OPTIONS.product(ACCEPT_OPTIONS, KEYS_OPTIONS).map do |i, a, k|
      { init: i, accept: a, keys: k, label: label(i, a, k) }
    end
  end

  CELLS = cells.freeze

  def key_for(cell, name)
    cell[:keys] ? name : name.to_s
  end

  # ---------- default: option ----------------------------------------------

  def test_default_literal_value_when_key_missing
    # Cells with init:strict + no default would raise "missing keyword".
    # A default is exactly what should make the attribute optional in strict.
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, default: 'fallback'
      end

      obj = klass.new({})
      assert_equal('fallback', obj.name, cell[:label])
      refute_predicate(obj, :attributes_errors?, cell[:label]) if cell[:accept] != :none
    end
  end

  def test_default_proc_receives_init_value
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, default: ->(value) { value.nil? ? 'fallback' : value.upcase }
      end

      assert_equal('fallback', klass.new({}).name,           cell[:label])
      assert_equal('RODRIGO',  klass.new(name: 'Rodrigo').name, cell[:label])
    end
  end

  def test_default_makes_attribute_not_required_even_under_strict_init
    # When init: :strict, attributes_are_all_required? returns true, BUT
    # __attributes_required_add explicitly skips attributes with a default.
    # Verify across the whole accept × keys grid.
    CELLS.select { |c| c[:init] == :strict }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, default: 'fallback'
        attribute :age,  accept: Numeric, default: 0
      end

      # Empty hash works because both attributes have defaults.
      obj = klass.new({})
      assert_equal('fallback', obj.name, cell[:label])
      assert_equal(0, obj.age, cell[:label])
    end
  end

  def test_default_value_is_validated_by_accept
    # When the default is a literal value and accept is on, the accept
    # check runs against the default. A mismatching default should record
    # an error (loose accept) or raise (strict accept).
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, default: 42  # int default, expects String
      end

      if cell[:accept] == :strict
        err = assert_raises(ArgumentError, cell[:label]) { klass.new({}) }
        assert_match(/kind of String/, err.message, cell[:label])
      else
        obj = klass.new({})
        assert_predicate(obj, :attributes_errors?, cell[:label])
        assert_match(/kind of String/, obj.attributes_errors[key_for(cell, :name)], cell[:label])
      end
    end
  end

  # ---------- freeze: option ----------------------------------------------

  def test_freeze_true_freezes_value
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, freeze: true
      end

      obj = klass.new(name: 'Rodrigo')
      assert_predicate(obj.name, :frozen?, cell[:label])
    end
  end

  def test_freeze_after_dup
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :tags, freeze: :after_dup
      end

      original = ['a', 'b']
      obj = klass.new(tags: original)

      assert_predicate(obj.tags, :frozen?, cell[:label])
      refute_same(original, obj.tags, "dup'd before freeze (#{cell[:label]})")
      refute_predicate(original, :frozen?, "original unfrozen (#{cell[:label]})")
    end
  end

  def test_freeze_after_clone_preserves_singleton_state
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :tags, freeze: :after_clone
      end

      original = ['a', 'b']
      def original.special_marker; :marker; end

      obj = klass.new(tags: original)

      assert_predicate(obj.tags, :frozen?, cell[:label])
      assert_equal(:marker, obj.tags.special_marker, "clone keeps singleton (#{cell[:label]})")
    end
  end

  # ---------- private: / protected: ----------------------------------------

  def test_private_attribute_reader_is_not_callable_externally
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :public_one,  accept: String
        attribute :secret,      accept: String, private: true

        define_method(:reveal) { secret }
      end

      obj = klass.new(public_one: 'p', secret: 'sssh')

      assert_equal('p', obj.public_one, cell[:label])
      assert_raises(NoMethodError, "private reader external (#{cell[:label]})") { obj.secret }
      assert_equal('sssh', obj.reveal, "internal access OK (#{cell[:label]})")
    end
  end

  def test_private_attribute_hidden_from_attributes_hash_but_visible_in_introspection
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :public_one, accept: String
        attribute :secret,     accept: String, private: true
      end

      obj = klass.new(public_one: 'p', secret: 'sssh')

      # `#attributes` only includes public attrs
      refute(obj.attributes.key?(key_for(cell, :secret)), "hidden from #attributes (#{cell[:label]})")
      assert(obj.attributes.key?(key_for(cell, :public_one)), "public visible (#{cell[:label]})")

      # `#defined_attributes` includes all
      assert_includes(obj.defined_attributes, key_for(cell, :secret), "in defined (#{cell[:label]})")
      assert_includes(obj.defined_attributes(:by_visibility)[:private], key_for(cell, :secret), cell[:label])
    end
  end

  def test_protected_attribute_reader_callable_from_same_class
    CELLS.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :public_one, accept: String
        attribute :secret,     accept: String, protected: true

        define_method(:reveal) { secret }
        define_method(:compare) { |other| other.send(:secret) == secret }
      end

      obj = klass.new(public_one: 'p', secret: 'x')
      other = klass.new(public_one: 'p', secret: 'x')

      assert_raises(NoMethodError, "protected blocks external (#{cell[:label]})") { obj.secret }
      assert_equal('x', obj.reveal, "internal access (#{cell[:label]})")
      assert(obj.compare(other), "same-class comparison (#{cell[:label]})")
    end
  end

  # ---------- accept: allow_nil: ------------------------------------------

  def test_accept_allow_nil_lets_nil_through
    # Only meaningful when accept is on.
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, allow_nil: true
        attribute :age,  accept: Numeric  # no allow_nil — nil age would fail
      end

      # Pass nil name explicitly + valid age → must succeed in both loose
      # and strict accept cells.
      obj = klass.new(name: nil, age: 1)
      assert_nil(obj.name, cell[:label])
      assert_equal(1, obj.age, cell[:label])
      refute_predicate(obj, :attributes_errors?, cell[:label]) if cell[:accept] == :base
    end
  end

  def test_accept_allow_nil_does_not_silence_non_nil_mismatches
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, allow_nil: true
        attribute :age,  accept: Numeric, default: 1
      end

      if cell[:accept] == :strict
        assert_raises(ArgumentError, cell[:label]) { klass.new(name: :sym) }
      else
        obj = klass.new(name: :sym)
        assert_predicate(obj, :attributes_errors?, cell[:label])
      end
    end
  end

  # ---------- accept: rejection_message: ----------------------------------

  def test_custom_rejection_message_string
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, rejection_message: 'must be a string'
        attribute :age,  accept: Numeric, default: 1
      end

      if cell[:accept] == :strict
        err = assert_raises(ArgumentError, cell[:label]) { klass.new(name: :sym) }
        assert_match(/must be a string/, err.message, cell[:label])
      else
        obj = klass.new(name: :sym)
        assert_equal('must be a string', obj.attributes_errors[key_for(cell, :name)], cell[:label])
      end
    end
  end

  def test_custom_rejection_message_proc_receives_key
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        attribute :name, accept: String, rejection_message: ->(key) { "#{key}: bad" }
        attribute :age,  accept: Numeric, default: 1
      end

      if cell[:accept] == :strict
        err = assert_raises(ArgumentError, cell[:label]) { klass.new(name: :sym) }
        # The key encoding depends on KeysAsSymbol; check for either string or symbol form.
        assert_match(/(:name|name): bad/, err.message, cell[:label])
      else
        obj = klass.new(name: :sym)
        msg = obj.attributes_errors[key_for(cell, :name)]
        assert_match(/(:name|name): bad/, msg, cell[:label])
      end
    end
  end

  # ---------- accept: reject: (inverse) -----------------------------------

  def test_reject_inverse_of_accept
    CELLS.select { |c| c[:accept] != :none }.each do |cell|
      klass = self.class.cell_klass(cell[:init], cell[:accept], cell[:keys]) do
        # `reject: Numeric` means "anything BUT Numeric is OK"
        attribute :name, reject: Numeric
        attribute :age,  accept: Numeric, default: 1
      end

      # Pass non-Numeric name → passes
      ok = klass.new(name: 'Rodrigo')
      assert_equal('Rodrigo', ok.name, cell[:label])
      refute_predicate(ok, :attributes_errors?, cell[:label]) if cell[:accept] == :base

      # Pass Numeric name → rejected
      if cell[:accept] == :strict
        err = assert_raises(ArgumentError, cell[:label]) { klass.new(name: 42) }
        assert_match(/expected to not be a kind of Numeric/, err.message, cell[:label])
      else
        bad = klass.new(name: 42)
        assert_match(/expected to not be a kind of Numeric/,
                     bad.attributes_errors[key_for(cell, :name)], cell[:label])
      end
    end
  end
end
