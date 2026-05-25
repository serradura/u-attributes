require 'test_helper'
require 'micro/entity'

ENTITY_MATRIX_HAS_ACTIVEMODEL =
  begin
    require 'active_model'
    true
  rescue LoadError
    false
  end

# Matrix test for Micro::Entity across every supported feature combination.
#
# Axes:
# - Base:          Micro::Entity  vs  Micro::Entity::Strict
# - Key access:    default (string/indifferent)  vs  KeysAsSymbol
# - Validations:   none  vs  ActiveModelValidations  (gated on activemodel being loadable)
#
# Invariants verified for every cell:
# - Basic instantiation from a hash works.
# - `accept:` on a nested Entity subclass coerces a hash to the entity.
# - An entity instance passes through (`accept` check succeeds, same object).
# - The block form of `attribute` defines an anonymous nested entity at runtime.
# - `#with_attribute` produces a new instance (immutability).
class Micro::EntityMatrixTest < Minitest::Test
  BASE_AXIS = [
    [:loose,  Micro::Entity,         false],
    [:strict, Micro::Entity::Strict, true],
  ].freeze

  KEYS_AXIS = [
    [:string, nil,                                            ->(name) { name.to_s }],
    [:symbol, Micro::Attributes.with(:keys_as_symbol),        ->(name) { name.to_sym }],
  ].freeze

  AM_AXIS =
    if ENTITY_MATRIX_HAS_ACTIVEMODEL
      [
        [:no_am, nil],
        [:am,    Micro::Attributes.with(:activemodel_validations)],
      ].freeze
    else
      [[:no_am, nil]].freeze
    end

  # Build a `[outer_class, nested_class]` pair for a given matrix cell.
  # Each axis contributes one feature module that we mix into the entity.
  # Classes are assigned to constants because ActiveModel uses `Class#name`
  # when rendering validation messages (anonymous classes raise).
  def self.build_cell(label, base, keys_module, am_module)
    const_label = label.tr('/', '_').gsub(/\W+/, '_').sub(/^_+/, '').sub(/_+$/, '')

    nested = Class.new(base) do
      include keys_module if keys_module
      include am_module if am_module

      attribute :value, accept: Integer
    end
    const_set("Nested_#{const_label}", nested)

    outer = Class.new(base) do
      include keys_module if keys_module
      include am_module if am_module

      attribute :name,   accept: String
      attribute :nested, accept: nested

      # Block form must always work — anon nested entity defined at runtime.
      attribute :inline do
        attribute :label, accept: String
      end

      # AM cells get a real validation rule so we can exercise `valid?`,
      # `errors`, and the AM→attributes_errors bridge in the assertions.
      validates :name, presence: true if am_module
    end
    const_set("Outer_#{const_label}", outer)

    [outer, nested]
  end

  CELLS = BASE_AXIS.flat_map do |base_label, base, strict|
    KEYS_AXIS.flat_map do |keys_label, keys_module, key_for|
      AM_AXIS.map do |am_label, am_module|
        label = "#{base_label}/#{keys_label}/#{am_label}"
        outer, nested = build_cell(label, base, keys_module, am_module)
        {
          label: label,
          strict: strict,
          key_for: key_for,
          outer: outer,
          nested: nested,
        }
      end
    end
  end.freeze

  def test_matrix_has_expected_size
    expected = ENTITY_MATRIX_HAS_ACTIVEMODEL ? 8 : 4
    assert_equal(expected, CELLS.size, 'unexpected matrix cardinality')
  end

  def test_initialization_and_attribute_readers_across_matrix
    CELLS.each do |cell|
      outer = cell[:outer]
      key = cell[:key_for]

      attrs = { name: 'Rodrigo', nested: { value: 42 }, inline: { label: 'hi' } }
      attrs[:dummy] = nil # ignored — never declared

      obj = outer.new(attrs)

      assert_equal('Rodrigo', obj.name, "name reader (#{cell[:label]})")
      assert_kind_of(cell[:nested], obj.nested, "nested coerced to entity (#{cell[:label]})")
      assert_equal(42, obj.nested.value, "nested value (#{cell[:label]})")
      assert_kind_of(::Micro::Entity, obj.inline, "inline coerced to entity (#{cell[:label]})")
      assert_equal('hi', obj.inline.label, "inline label (#{cell[:label]})")

      # attributes hash keys follow the KeysAsSymbol axis.
      assert(obj.attributes.key?(key.call(:name)), "name in attributes (#{cell[:label]})")
      refute_predicate(obj, :attributes_errors?, "no accept errors (#{cell[:label]})")
    end
  end

  def test_entity_instance_passes_through_without_re_coercion
    CELLS.each do |cell|
      pre_built = cell[:nested].new(value: 7)

      obj = cell[:outer].new(
        name: 'X',
        nested: pre_built,
        inline: { label: 'L' },
      )

      assert_same(pre_built, obj.nested, "entity instance not re-coerced (#{cell[:label]})")
    end
  end

  def test_block_form_validates_nested_attributes
    CELLS.each do |cell|
      if cell[:strict]
        err = assert_raises(ArgumentError, "strict should raise (#{cell[:label]})") do
          cell[:outer].new(
            name: 'X',
            nested: { value: 1 },
            inline: { label: :not_a_string },
          )
        end
        assert_match(/One or more attributes were rejected/, err.message, cell[:label])
      else
        obj = cell[:outer].new(
          name: 'X',
          nested: { value: 1 },
          inline: { label: :not_a_string },
        )
        assert_predicate(obj.inline, :attributes_errors?, "inline has the detail (#{cell[:label]})")

        # Deep-nesting bubble: the outer mirrors descendant invalidity via
        # a `'is invalid'` marker (the leaf retains the full message).
        assert_predicate(obj, :attributes_errors?, "outer mirrors inline invalidity (#{cell[:label]})")
        key_for_inline = cell[:key_for].call(:inline)
        assert_equal('is invalid', obj.attributes_errors[key_for_inline],
                     "outer carries the marker (#{cell[:label]})")
      end
    end
  end

  def test_strict_rejects_invalid_top_level_input
    CELLS.select { |c| c[:strict] }.each do |cell|
      err = assert_raises(ArgumentError, "strict missing-key (#{cell[:label]})") do
        cell[:outer].new(name: 'X')
      end
      assert_match(/missing keyword/, err.message, cell[:label])

      err = assert_raises(ArgumentError, "strict accept-error (#{cell[:label]})") do
        cell[:outer].new(
          name: :not_a_string,
          nested: { value: 1 },
          inline: { label: 'ok' },
        )
      end
      assert_match(/One or more attributes were rejected/, err.message, cell[:label])
    end
  end

  def test_loose_cells_record_accept_errors_without_raising
    CELLS.reject { |c| c[:strict] }.each do |cell|
      obj = cell[:outer].new(
        name: :not_a_string,
        nested: 'oops',
        inline: { label: 'ok' },
      )

      assert_predicate(obj, :attributes_errors?, "loose accept errors (#{cell[:label]})")
      key = cell[:key_for]
      assert_includes(obj.attributes_errors.keys, key.call(:name), cell[:label])
      assert_includes(obj.attributes_errors.keys, key.call(:nested), cell[:label])
    end
  end

  def test_with_attribute_returns_a_new_instance
    CELLS.reject { |c| c[:strict] }.each do |cell|
      obj = cell[:outer].new(
        name: 'A',
        nested: { value: 1 },
        inline: { label: 'L' },
      )

      updated = obj.with_attribute(:name, 'B')

      refute_same(obj, updated, "with_attribute returns new instance (#{cell[:label]})")
      assert_equal('A', obj.name,     "original unchanged (#{cell[:label]})")
      assert_equal('B', updated.name, "updated reflects change (#{cell[:label]})")
    end
  end

  def test_diff_is_available_across_matrix
    CELLS.reject { |c| c[:strict] }.each do |cell|
      a = cell[:outer].new(name: 'A', nested: { value: 1 }, inline: { label: 'L' })
      b = a.with_attribute(:name, 'B')

      diff = a.diff_attributes(b)
      key = cell[:key_for]

      assert(diff.changed?(key.call(:name)), "diff sees name change (#{cell[:label]})")
      refute(diff.changed?(key.call(:nested)), "nested unchanged (#{cell[:label]})")
    end
  end

  # -- ActiveModel-specific assertions (only when AM is loadable) ---------------------------

  if ENTITY_MATRIX_HAS_ACTIVEMODEL
    AM_CELLS = CELLS.select { |c| c[:outer].include?(Micro::Attributes::Features::ActiveModelValidations) }

    def test_activemodel_valid_predicate_works_with_entity
      AM_CELLS.each do |cell|
        valid = cell[:outer].new(name: 'Rodrigo', nested: { value: 1 }, inline: { label: 'L' })
        assert_predicate(valid, :valid?, "valid (#{cell[:label]})")

        next if cell[:strict] # strict raises on accept errors before validations are interesting

        invalid = cell[:outer].new(name: '', nested: { value: 1 }, inline: { label: 'L' })
        refute_predicate(invalid, :valid?, "invalid blank name (#{cell[:label]})")
        assert_match(/can't be blank/, invalid.errors[:name].first.to_s, cell[:label])
      end
    end

    def test_activemodel_errors_merge_into_attributes_errors
      # When accept and activemodel_validations are combined, AM errors are surfaced via
      # attributes_errors (loose cells). Strict cells raise instead.
      AM_CELLS.reject { |c| c[:strict] }.each do |cell|
        obj = cell[:outer].new(name: '', nested: { value: 1 }, inline: { label: 'L' })

        key = cell[:key_for]
        assert_predicate(obj, :attributes_errors?, "errors present (#{cell[:label]})")
        assert_includes(obj.attributes_errors.keys, key.call(:name), cell[:label])
      end
    end
  end
end
