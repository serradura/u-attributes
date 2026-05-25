require 'test_helper'

WITH_MATRIX_HAS_ACTIVEMODEL =
  begin
    require 'active_model'
    true
  rescue LoadError
    false
  end

# Exhaustive behavior matrix for `Micro::Attributes.with(...)`.
#
# 5 axes — each one is a real, observable difference in how an instance behaves:
#   - init:   [:none, :base, :strict]   → no auto-init / `:initialize` / `initialize: :strict`
#   - accept: [:none, :base, :strict]   → no accept / `:accept` / `accept: :strict`
#   - diff:   [false, true]             → no diff / `:diff`
#   - keys:   [false, true]             → string (indifferent) keys / `:keys_as_symbol`
#   - am:     [false, true]             → no AM / `:activemodel_validations`  (gated)
#
# 3 × 3 × 2 × 2 × 2 = 72 combinations, minus the all-empty cell = **71 cells** —
# which is exactly the size of the internal `Options::KEYS_TO_MODULES` table.
#
# Per-cell behavior is verified by separate `test_*_across_matrix` methods,
# each iterating only the cells where that behavior is observable. With AM
# loadable: ~520+ assertions across the matrix; without AM: ~270+.
class Micro::Attributes::WithMatrixTest < Minitest::Test
  INIT_OPTIONS   = [:none, :base, :strict].freeze
  ACCEPT_OPTIONS = [:none, :base, :strict].freeze
  DIFF_OPTIONS   = [false, true].freeze
  KEYS_OPTIONS   = [false, true].freeze
  AM_OPTIONS     = WITH_MATRIX_HAS_ACTIVEMODEL ? [false, true].freeze : [false].freeze

  # Translate a cell coordinate into the `*args` you'd pass to `Micro::Attributes.with`.
  # Strict variants go into a trailing hash; the rest are positional symbols.
  def self.build_args(init, accept, diff, keys, am)
    args = []
    extra = {}
    args << :initialize             if init == :base
    args << :accept                 if accept == :base
    args << :diff                   if diff
    args << :keys_as_symbol         if keys
    args << :activemodel_validations if am
    extra[:initialize] = :strict    if init == :strict
    extra[:accept]     = :strict    if accept == :strict
    args << extra unless extra.empty?
    args
  end

  def self.cell_label(init, accept, diff, keys, am)
    parts = ["init_#{init}", "accept_#{accept}"]
    parts << 'diff'     if diff
    parts << 'keys_sym' if keys
    parts << 'am'       if am
    parts.join('_')
  end

  # Build one cell's class. Constants are required because ActiveModel renders
  # validation error messages through `Class#name`, which is nil for anonymous
  # classes (raises "Class name cannot be blank").
  def self.build_klass(init, accept, diff, keys, am, label)
    args = build_args(init, accept, diff, keys, am)

    klass = Class.new
    klass.send(:include, Micro::Attributes.with(*args))

    # When `:initialize` is not in `with(...)`, the user is expected to
    # define their own constructor — this is the canonical pattern.
    if init == :none
      klass.class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def initialize(arg)
          self.attributes = arg
        end
      RUBY
    end

    klass.class_eval do
      attribute :name, accept: String,  validates: { presence: true }
      attribute :age,  accept: Numeric
    end

    klass
  end

  CELLS =
    INIT_OPTIONS.product(ACCEPT_OPTIONS, DIFF_OPTIONS, KEYS_OPTIONS, AM_OPTIONS)
      .reject { |i, a, d, k, m| i == :none && a == :none && !d && !k && !m }
      .map do |i, a, d, k, m|
        label = cell_label(i, a, d, k, m)
        klass = build_klass(i, a, d, k, m, label)
        const_set("Cell_#{label}", klass)
        { init: i, accept: a, diff: d, keys: k, am: m, label: label, klass: klass }
      end.freeze

  # -- sanity: matrix is the size we expect ---------------------------------

  def test_matrix_cardinality
    expected = WITH_MATRIX_HAS_ACTIVEMODEL ? 71 : 35
    assert_equal(expected, CELLS.size, "matrix size")

    # And every cell must resolve to a real module (no silently-missing combos).
    CELLS.each do |cell|
      mod = Micro::Attributes.with(*self.class.build_args(cell[:init], cell[:accept], cell[:diff], cell[:keys], cell[:am]))
      assert_kind_of(Module, mod, cell[:label])
    end
  end

  # -- universal: basic construction succeeds with valid input --------------

  def test_basic_construction_across_matrix
    CELLS.each do |cell|
      obj = cell[:klass].new(name: 'Rodrigo', age: 34)

      assert_equal('Rodrigo', obj.name, "name reader (#{cell[:label]})")
      assert_equal(34,        obj.age,  "age reader (#{cell[:label]})")
    end
  end

  # -- init axis ------------------------------------------------------------

  def test_strict_init_raises_on_missing_keys_across_matrix
    CELLS.select { |c| c[:init] == :strict }.each do |cell|
      err = assert_raises(ArgumentError, "expected raise (#{cell[:label]})") do
        cell[:klass].new(name: 'Rodrigo')
      end
      assert_match(/missing keyword/, err.message, cell[:label])
    end
  end

  def test_non_strict_init_does_not_require_keys_across_matrix
    CELLS.reject { |c| c[:init] == :strict || c[:accept] == :strict }.each do |cell|
      # missing :age is fine for non-strict-init AND non-strict-accept cells
      # (strict-accept would raise because nil ≠ Numeric).
      obj = cell[:klass].new(name: 'Rodrigo')
      assert_equal('Rodrigo', obj.name, cell[:label])
      assert_nil(obj.age, cell[:label])
    end
  end

  def test_with_attribute_returns_new_instance_when_init_included_across_matrix
    CELLS.select { |c| c[:init] != :none }.each do |cell|
      obj = cell[:klass].new(name: 'Rodrigo', age: 34)
      updated = obj.with_attribute(:name, 'Other')

      refute_same(obj, updated, "fresh instance (#{cell[:label]})")
      assert_equal('Rodrigo', obj.name,     "original unchanged (#{cell[:label]})")
      assert_equal('Other',   updated.name, "updated value (#{cell[:label]})")
    end
  end

  def test_no_init_means_no_with_attribute_across_matrix
    CELLS.select { |c| c[:init] == :none }.each do |cell|
      obj = cell[:klass].new(name: 'Rodrigo', age: 34)
      refute_respond_to(obj, :with_attribute,  cell[:label])
      refute_respond_to(obj, :with_attributes, cell[:label])
    end
  end

  # -- accept axis ----------------------------------------------------------

  def test_accept_records_errors_when_loose_across_matrix
    CELLS.select { |c| c[:accept] == :base }.each do |cell|
      obj = cell[:klass].new(name: :not_a_string, age: 'not numeric')

      assert_predicate(obj, :attributes_errors?, "errors? (#{cell[:label]})")

      key_name = cell[:keys] ? :name : 'name'
      key_age  = cell[:keys] ? :age  : 'age'

      assert_includes(obj.attributes_errors, key_name, cell[:label])
      assert_includes(obj.attributes_errors, key_age,  cell[:label])
      assert_match(/kind of String/,  obj.attributes_errors[key_name], cell[:label])
      assert_match(/kind of Numeric/, obj.attributes_errors[key_age],  cell[:label])
    end
  end

  def test_accept_raises_when_strict_across_matrix
    CELLS.select { |c| c[:accept] == :strict }.each do |cell|
      err = assert_raises(ArgumentError, "expected raise (#{cell[:label]})") do
        cell[:klass].new(name: :not_a_string, age: 'not numeric')
      end
      assert_match(/One or more attributes were rejected/, err.message, cell[:label])
    end
  end

  def test_no_accept_passes_bad_types_through_across_matrix
    CELLS.select { |c| c[:accept] == :none }.each do |cell|
      obj = cell[:klass].new(name: :not_a_string, age: 'not numeric')

      assert_equal(:not_a_string, obj.name, cell[:label])
      assert_equal('not numeric', obj.age,  cell[:label])

      # Without the accept module the introspection methods don't exist.
      refute_respond_to(obj, :attributes_errors,  cell[:label])
      refute_respond_to(obj, :attributes_errors?, cell[:label])
      refute_respond_to(obj, :rejected_attributes, cell[:label])
      refute_respond_to(obj, :accepted_attributes, cell[:label])
    end
  end

  # -- diff axis ------------------------------------------------------------

  def test_diff_available_when_included_across_matrix
    CELLS.select { |c| c[:diff] }.each do |cell|
      a = cell[:klass].new(name: 'A', age: 1)
      b = cell[:klass].new(name: 'B', age: 1)

      changes = a.diff_attributes(b)
      key_name = cell[:keys] ? :name : 'name'
      key_age  = cell[:keys] ? :age  : 'age'

      assert(changes.changed?(key_name), "name changed (#{cell[:label]})")
      refute(changes.changed?(key_age),  "age unchanged (#{cell[:label]})")
    end
  end

  def test_diff_unavailable_when_excluded_across_matrix
    CELLS.reject { |c| c[:diff] }.each do |cell|
      obj = cell[:klass].new(name: 'A', age: 1)
      refute_respond_to(obj, :diff_attributes, cell[:label])
    end
  end

  # -- keys axis ------------------------------------------------------------

  def test_keys_as_symbol_uses_symbols_across_matrix
    CELLS.select { |c| c[:keys] }.each do |cell|
      obj = cell[:klass].new(name: 'X', age: 1)
      attrs = obj.attributes

      assert(attrs.key?(:name), "symbol key present (#{cell[:label]})")
      refute(attrs.key?('name'), "string key absent (#{cell[:label]})")

      assert(obj.attribute?(:name),    "attribute?(:sym) (#{cell[:label]})")
      refute(obj.attribute?('name'),   "attribute?('str') (#{cell[:label]})")
      assert_equal('X',  obj.attribute(:name),  cell[:label])
      assert_nil(obj.attribute('name'),         cell[:label])
    end
  end

  def test_default_keys_are_strings_across_matrix
    CELLS.reject { |c| c[:keys] }.each do |cell|
      obj = cell[:klass].new(name: 'X', age: 1)
      attrs = obj.attributes

      assert(attrs.key?('name'), "string key present (#{cell[:label]})")
      refute(attrs.key?(:name),  "symbol key absent (#{cell[:label]})")

      # Indifferent access via attribute?/attribute (both work in default mode).
      assert(obj.attribute?(:name),    cell[:label])
      assert(obj.attribute?('name'),   cell[:label])
      assert_equal('X', obj.attribute(:name),  cell[:label])
      assert_equal('X', obj.attribute('name'), cell[:label])
    end
  end

  # -- activemodel axis (gated) --------------------------------------------

  if WITH_MATRIX_HAS_ACTIVEMODEL
    def test_am_valid_with_proper_input_across_matrix
      CELLS.select { |c| c[:am] }.each do |cell|
        obj = cell[:klass].new(name: 'Rodrigo', age: 34)
        assert_predicate(obj, :valid?, "valid (#{cell[:label]})")
        assert_empty(obj.errors, "errors empty (#{cell[:label]})")
      end
    end

    def test_am_records_presence_failure_when_loose_across_matrix
      # The `validates: { presence: true }` rule fails when name is blank.
      # Strict-accept raises on `:not_a_string`, so for the AM presence
      # behavior we test cells where accept won't intercept first.
      CELLS.select { |c| c[:am] && c[:accept] != :strict }.each do |cell|
        obj = cell[:klass].new(name: '', age: 34)

        refute_predicate(obj, :valid?, "invalid (#{cell[:label]})")
        assert(obj.errors[:name].any?, "name errors (#{cell[:label]})")
        assert_match(/can't be blank/, obj.errors[:name].first.to_s, cell[:label])

        # For cells that ALSO have accept, the AM error is bridged into
        # attributes_errors via the WithAccept variant.
        if cell[:accept] == :base
          key_name = cell[:keys] ? :name : 'name'
          assert_includes(obj.attributes_errors, key_name, "bridge (#{cell[:label]})")
        end
      end
    end

    def test_am_skips_validations_when_accept_already_rejected_across_matrix
      # `WithAccept` variant short-circuits: AM doesn't run if accept failed.
      # `WithAcceptStrict` raises before AM runs.
      # We assert the loose case here; strict already raises (covered above).
      CELLS.select { |c| c[:am] && c[:accept] == :base }.each do |cell|
        obj = cell[:klass].new(name: :symbol, age: 1)

        # accept rejected name as not a String. AM presence on name was skipped,
        # so the only error key is the accept-failure (no can't-be-blank merge).
        key_name = cell[:keys] ? :name : 'name'
        assert_match(/kind of String/, obj.attributes_errors[key_name], cell[:label])
      end
    end

    def test_no_am_means_no_valid_method_across_matrix
      CELLS.reject { |c| c[:am] }.each do |cell|
        obj = cell[:klass].new(name: 'X', age: 1)
        refute_respond_to(obj, :valid?, cell[:label])
        refute_respond_to(obj, :errors, cell[:label])
      end
    end
  end
end
