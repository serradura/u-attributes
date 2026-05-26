require 'test_helper'

# Exhaustive coverage for `attribute!` — the subclass-only overwrite macro
# (defined in `Macros::ForSubclasses`). Pins down that EVERY per-attribute
# option can be cleanly overridden in a subclass, across the feature
# combinations that interact with each option.
class Micro::Attributes::InheritanceOverwriteTest < Minitest::Test
  # `attribute!` is only available on subclasses, not on the class that
  # first included Micro::Attributes — guard this invariant.
  class BaseGuard
    include Micro::Attributes.with(:initialize)
    attribute :x
  end

  def test_attribute_bang_is_private_on_the_base_class
    refute_respond_to(BaseGuard, :attribute!)
    assert(BaseGuard.respond_to?(:attribute, true), 'public attribute still available')
  end

  class ChildGuard < BaseGuard; end

  def test_attribute_bang_is_available_on_subclasses
    assert_respond_to(ChildGuard, :attribute!)
  end

  # ---------- override accept: ---------------------------------------------

  class BaseAccept
    include Micro::Attributes.with(:initialize, :accept)
    attribute :v, accept: String
  end

  class ChildAccept < BaseAccept
    attribute! :v, accept: Numeric
  end

  def test_attribute_bang_overrides_accept_kind
    parent_bad = BaseAccept.new(v: 1)
    assert_predicate(parent_bad, :attributes_errors?, 'parent rejects non-String')

    child_ok = ChildAccept.new(v: 1)
    refute_predicate(child_ok, :attributes_errors?, 'child accepts Numeric')

    child_bad = ChildAccept.new(v: 'str')
    assert_predicate(child_bad, :attributes_errors?, 'child rejects non-Numeric')
  end

  class ChildAcceptStrict < BaseAccept
    include Micro::Attributes.with(:initialize, accept: :strict)
    attribute! :v, accept: Numeric
  end

  def test_attribute_bang_with_accept_strict_in_child_raises
    assert_raises(ArgumentError) { ChildAcceptStrict.new(v: 'str') }
    assert_equal(1, ChildAcceptStrict.new(v: 1).v)
  end

  # ---------- override default: -------------------------------------------

  class BaseDefault
    include Micro::Attributes.with(:initialize)
    attribute :name, default: 'parent'
    attribute :age,  default: 0
  end

  class ChildDefault < BaseDefault
    attribute! :name, default: 'child'
  end

  def test_attribute_bang_overrides_default_value
    assert_equal('parent', BaseDefault.new({}).name)
    assert_equal('child',  ChildDefault.new({}).name)
    # Unchanged attribute keeps its parent default.
    assert_equal(0, ChildDefault.new({}).age)
  end

  class GrandchildDefault < ChildDefault
    attribute! :name, default: 'grandchild'
  end

  def test_attribute_bang_overrides_default_through_three_levels
    assert_equal('parent',     BaseDefault.new({}).name)
    assert_equal('child',      ChildDefault.new({}).name)
    assert_equal('grandchild', GrandchildDefault.new({}).name)
  end

  # ---------- override default: with proc ---------------------------------

  class BaseProcDefault
    include Micro::Attributes.with(:initialize)
    attribute :name, default: ->(value) { value.to_s.strip }
  end

  class ChildProcDefault < BaseProcDefault
    attribute! :name, default: ->(value) { value.to_s.upcase }
  end

  def test_attribute_bang_overrides_proc_default
    assert_equal('hi',   BaseProcDefault.new(name: '  hi  ').name)
    assert_equal('  HI  ', ChildProcDefault.new(name: '  hi  ').name)
  end

  # ---------- override visibility -----------------------------------------

  class BaseVisibility
    include Micro::Attributes.with(:initialize)
    attribute :secret, default: 'sssh', private: true
    attribute :exposed, default: 'open'

    def reveal; secret; end
  end

  class ChildVisibility < BaseVisibility
    attribute! :secret, default: 'sssh'  # back to public
    attribute! :exposed, default: 'open', private: true
  end

  def test_attribute_bang_changes_visibility
    parent = BaseVisibility.new({})
    assert_raises(NoMethodError) { parent.secret }
    assert_equal('open', parent.exposed)

    child = ChildVisibility.new({})
    assert_equal('sssh', child.secret, 'child reopened secret as public')
    assert_raises(NoMethodError) { child.exposed }
  end

  def test_attribute_bang_visibility_change_reflects_in_attributes_hash
    parent = BaseVisibility.new({})
    refute(parent.attributes.key?('secret'), 'private hidden')
    assert(parent.attributes.key?('exposed'))

    child = ChildVisibility.new({})
    assert(child.attributes.key?('secret'),   'reopened public visible')
    refute(child.attributes.key?('exposed'),  'newly private hidden')
  end

  # ---------- override freeze: --------------------------------------------

  class BaseFreeze
    include Micro::Attributes.with(:initialize)
    attribute :name, default: 'parent'
  end

  class ChildFreezeTrue < BaseFreeze
    attribute! :name, freeze: true
  end

  class ChildFreezeAfterDup < BaseFreeze
    attribute! :name, freeze: :after_dup
  end

  def test_attribute_bang_introduces_freeze
    refute_predicate(BaseFreeze.new(name: +'A').name, :frozen?, 'parent unfrozen')
    assert_predicate(ChildFreezeTrue.new(name: 'A').name, :frozen?)
    assert_predicate(ChildFreezeAfterDup.new(name: +'A').name, :frozen?)
  end

  class BaseFreezeTrue
    include Micro::Attributes.with(:initialize)
    attribute :name, freeze: true
  end

  class ChildClearFreeze < BaseFreezeTrue
    attribute! :name  # without freeze option — must clear the parent's
  end

  def test_attribute_bang_clears_freeze_when_omitted
    assert_predicate(BaseFreezeTrue.new(name: 'A').name, :frozen?)
    refute_predicate(ChildClearFreeze.new(name: +'A').name, :frozen?,
                     'child without freeze: should not inherit parent freezing')
  end

  # ---------- override required: ------------------------------------------

  class BaseRequired
    include Micro::Attributes.with(:initialize)
    attribute :name, required: true
    attribute :age, default: 0
  end

  class ChildRequiredCleared < BaseRequired
    attribute! :name, default: 'fallback'
  end

  def test_attribute_bang_with_default_removes_required
    assert_raises(ArgumentError) { BaseRequired.new({}) }

    obj = ChildRequiredCleared.new({})
    assert_equal('fallback', obj.name, 'default makes it optional')
  end

  # Regression for M1: under `Initialize::Strict` the parent marks every
  # attribute as required via `attributes_are_all_required?`. The child
  # must be able to relax that by giving an attribute a default — pre-fix,
  # the inherited entry in `__attributes_required__` was never removed and
  # `Child.new({})` raised "missing keyword".
  class BaseStrictRequired
    include Micro::Attributes.with(initialize: :strict)
    attribute :name
    attribute :age
  end

  class ChildRelaxesUnderStrict < BaseStrictRequired
    attribute! :name, default: 'fallback'
  end

  def test_attribute_bang_with_default_clears_inherited_strict_required
    # Parent: both required.
    assert_raises(ArgumentError) { BaseStrictRequired.new(name: 'x') }
    assert_raises(ArgumentError) { BaseStrictRequired.new(age: 1) }

    # Child: `name` now has a default and is no longer required;
    # `age` still inherits the strict requirement.
    obj = ChildRelaxesUnderStrict.new(age: 1)
    assert_equal('fallback', obj.name, 'default makes :name optional')
    assert_equal(1, obj.age)

    err = assert_raises(ArgumentError) { ChildRelaxesUnderStrict.new({}) }
    assert_match(/missing keyword: :age/, err.message,
                 ':age must still be required after the relaxation of :name')
  end

  # ---------- adding brand-new attribute via attribute! -------------------

  class BaseAddNew
    include Micro::Attributes.with(:initialize)
    attribute :a
  end

  class ChildAddNew < BaseAddNew
    attribute! :b, default: 'b'
    attribute! :c, default: 'c'
  end

  def test_attribute_bang_can_add_new_attributes
    assert_equal(['a'], BaseAddNew.attributes)
    assert_equal(['a', 'b', 'c'], ChildAddNew.attributes)

    obj = ChildAddNew.new(a: 'A')
    assert_equal('A', obj.a)
    assert_equal('b', obj.b)
    assert_equal('c', obj.c)
  end

  # ---------- parent unchanged after override ------------------------------

  class BaseUnchanged
    include Micro::Attributes.with(:initialize, :accept)
    attribute :name, accept: String, default: 'parent'
  end

  class ChildUnchanged < BaseUnchanged
    attribute! :name, accept: Numeric, default: 99
  end

  def test_overriding_in_child_does_not_mutate_parent
    parent = BaseUnchanged.new({})
    assert_equal('parent', parent.name)
    refute_predicate(parent, :attributes_errors?, 'parent default String still passes')

    child = ChildUnchanged.new({})
    assert_equal(99, child.name)
    refute_predicate(child, :attributes_errors?, 'child default Numeric still passes')

    # Re-check parent after child instantiation — no shared state mutation.
    parent2 = BaseUnchanged.new({})
    assert_equal('parent', parent2.name)
    refute_predicate(parent2, :attributes_errors?)
  end

  # ---------- with KeysAsSymbol -------------------------------------------

  class BaseKeysSymbol
    include Micro::Attributes.with(:initialize, :keys_as_symbol, :accept)
    attribute :name, accept: String
  end

  class ChildKeysSymbol < BaseKeysSymbol
    attribute! :name, accept: Numeric
  end

  def test_attribute_bang_works_under_keys_as_symbol
    parent_bad = BaseKeysSymbol.new(name: 1)
    assert_predicate(parent_bad, :attributes_errors?)
    assert(parent_bad.attributes_errors.key?(:name), 'symbol key in errors')

    child_ok = ChildKeysSymbol.new(name: 1)
    refute_predicate(child_ok, :attributes_errors?)
    assert(child_ok.attributes.key?(:name), 'symbol key in attributes')
  end

  # ---------- multi-attribute! in same body --------------------------------

  class BaseMulti
    include Micro::Attributes.with(:initialize, :accept)
    attribute :a, accept: String
    attribute :b, accept: String
    attribute :c, accept: String
  end

  class ChildMulti < BaseMulti
    attribute! :a, accept: Numeric, default: 1
    attribute! :b, accept: Symbol, default: :b
    # :c left untouched
  end

  def test_multiple_attribute_bang_in_one_child
    obj = ChildMulti.new(c: 'C')

    assert_equal(1,   obj.a)
    assert_equal(:b,  obj.b)
    assert_equal('C', obj.c)

    refute_predicate(obj, :attributes_errors?)

    # Confirm c still uses parent's String accept.
    bad_c = ChildMulti.new(c: 42)
    assert_predicate(bad_c, :attributes_errors?)
    assert_match(/kind of String/, bad_c.attributes_errors['c'])
  end
end
