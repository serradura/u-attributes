require 'test_helper'

COMPOSITION_MATRIX_HAS_ACTIVEMODEL =
  begin
    require 'active_model'
    true
  rescue LoadError
    false
  end

# Matrix test exercising composition behavior — block-form attribute,
# hash coercion, deep validation — across every supported feature
# combination of `Micro::Attributes.new(...)`.
#
# Axes:
# - Strict:        loose vs strict (initialize: :strict + accept: :strict)
# - Key access:    default (string/indifferent) vs KeysAsSymbol
# - Validations:   none vs ActiveModelValidations (gated on activemodel being loadable)
#
# Invariants verified for every cell:
# - Basic instantiation from a hash works.
# - `accept:` on a nested class coerces a hash to the entity.
# - An instance passes through (`accept` check succeeds, same object).
# - The block form of `attribute` defines an anonymous nested at runtime.
# - `#with_attribute` produces a new instance (immutability).
class Micro::Attributes::CompositionMatrixTest < Minitest::Test
  STRICT_AXIS = [
    [:loose,  false, {}],
    [:strict, true,  { initialize: :strict, accept: :strict }],
  ].freeze

  KEYS_AXIS = [
    [:string, {},                  ->(name) { name.to_s }],
    [:symbol, { keys_as: :symbol }, ->(name) { name.to_sym }],
  ].freeze

  AM_AXIS =
    if COMPOSITION_MATRIX_HAS_ACTIVEMODEL
      [
        [:no_am, {}],
        [:am,    { active_model: :validations }],
      ].freeze
    else
      [[:no_am, {}]].freeze
    end

  # Build a `[outer_class, nested_class]` pair for a given matrix cell.
  # Classes are assigned to constants because ActiveModel uses `Class#name`
  # when rendering validation messages (anonymous classes raise).
  def self.build_cell(label, strict_opts, keys_opts, am_opts)
    const_label = label.tr('/', '_').gsub(/\W+/, '_').sub(/^_+/, '').sub(/_+$/, '')

    base_opts = strict_opts.merge(keys_opts).merge(am_opts)
    has_am = !am_opts.empty?

    nested = Micro::Attributes.new(**base_opts) do
      attribute :value, accept: Integer
    end
    const_set("Nested_#{const_label}", nested)

    outer = Micro::Attributes.new(**base_opts) do
      attribute :name,   accept: String
      attribute :nested, accept: nested

      # Block form must always work — anon nested defined at runtime.
      attribute :inline do
        attribute :label, accept: String
      end
    end
    # AM cells get a real validation rule so we can exercise `valid?`,
    # `errors`, and the AM→attributes_errors bridge in the assertions.
    outer.validates(:name, presence: true) if has_am
    const_set("Outer_#{const_label}", outer)

    [outer, nested]
  end

  CELLS = STRICT_AXIS.flat_map do |strict_label, strict, strict_opts|
    KEYS_AXIS.flat_map do |keys_label, keys_opts, key_for|
      AM_AXIS.map do |am_label, am_opts|
        label = "#{strict_label}/#{keys_label}/#{am_label}"
        outer, nested = build_cell(label, strict_opts, keys_opts, am_opts)
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
    expected = COMPOSITION_MATRIX_HAS_ACTIVEMODEL ? 8 : 4
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
      assert_kind_of(cell[:nested], obj.nested, "nested coerced (#{cell[:label]})")
      assert_equal(42, obj.nested.value, "nested value (#{cell[:label]})")
      assert(obj.inline.class.include?(::Micro::Attributes), "inline includes Attributes (#{cell[:label]})")
      assert_equal('hi', obj.inline.label, "inline label (#{cell[:label]})")

      assert(obj.attributes.key?(key.call(:name)), "name in attributes (#{cell[:label]})")
      refute_predicate(obj, :attributes_errors?, "no accept errors (#{cell[:label]})")
    end
  end

  def test_instance_passes_through_without_re_coercion
    CELLS.each do |cell|
      pre_built = cell[:nested].new(value: 7)

      obj = cell[:outer].new(
        name: 'X',
        nested: pre_built,
        inline: { label: 'L' },
      )

      assert_same(pre_built, obj.nested, "instance not re-coerced (#{cell[:label]})")
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
        assert_predicate(obj.inline, :attributes_errors?, "inline has detail (#{cell[:label]})")

        # Deep bubble: outer mirrors descendant invalidity via marker.
        assert_predicate(obj, :attributes_errors?, "outer mirrors inline (#{cell[:label]})")
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

      refute_same(obj, updated, "with_attribute returns new (#{cell[:label]})")
      assert_equal('A', obj.name, cell[:label])
      assert_equal('B', updated.name, cell[:label])
    end
  end

  # -- ActiveModel-specific assertions (only when AM is loadable) -----------

  if COMPOSITION_MATRIX_HAS_ACTIVEMODEL
    AM_CELLS = CELLS.select { |c| c[:outer].include?(Micro::Attributes::Features::ActiveModelValidations) }

    def test_am_valid_predicate_works
      AM_CELLS.each do |cell|
        valid = cell[:outer].new(name: 'Rodrigo', nested: { value: 1 }, inline: { label: 'L' })
        assert_predicate(valid, :valid?, "valid (#{cell[:label]})")

        next if cell[:strict]

        invalid = cell[:outer].new(name: '', nested: { value: 1 }, inline: { label: 'L' })
        refute_predicate(invalid, :valid?, "invalid blank name (#{cell[:label]})")
        assert_match(/can't be blank/, invalid.errors[:name].first.to_s, cell[:label])
      end
    end

    def test_am_errors_merge_into_attributes_errors
      AM_CELLS.reject { |c| c[:strict] }.each do |cell|
        obj = cell[:outer].new(name: '', nested: { value: 1 }, inline: { label: 'L' })

        key = cell[:key_for]
        assert_predicate(obj, :attributes_errors?, "errors present (#{cell[:label]})")
        assert_includes(obj.attributes_errors.keys, key.call(:name), cell[:label])
      end
    end
  end
end
