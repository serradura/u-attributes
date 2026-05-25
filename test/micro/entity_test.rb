require 'test_helper'
require 'micro/entity'

class Micro::EntityTest < Minitest::Test
  class Person < Micro::Entity
    attribute :name
    attribute :age
  end

  def test_initializer_with_partial_hash
    person = Person.new({})

    assert_nil(person.name)
    assert_nil(person.age)
    assert_equal({'name' => nil, 'age' => nil}, person.attributes)
  end

  def test_initializer_with_a_full_hash
    person = Person.new(name: 'Rodrigo', age: 34)

    assert_equal('Rodrigo', person.name)
    assert_equal(34, person.age)
    assert_equal({'name' => 'Rodrigo', 'age' => 34}, person.attributes)
  end

  def test_with_attribute_returns_a_new_instance
    person = Person.new(name: 'Rodrigo')

    updated = person.with_attribute(:age, 34)

    refute_same(person, updated)
    assert_equal('Rodrigo', updated.name)
    assert_equal(34, updated.age)

    assert_nil(person.age)
  end

  def test_setters_are_not_defined
    person = Person.new(name: 'Rodrigo')

    assert_raises(NoMethodError) { person.name = 'Other' }
  end

  class User < Micro::Entity
    attribute :name, accept: String
    attribute :age, accept: Numeric
  end

  def test_accept_validations
    user = User.new(name: 'Rodrigo', age: 34)

    assert_predicate(user, :accepted_attributes?)
    refute_predicate(user, :attributes_errors?)

    invalid = User.new(name: :rodrigo, age: '34')

    assert_predicate(invalid, :attributes_errors?)
    assert_equal(
      {'name' => 'expected to be a kind of String', 'age' => 'expected to be a kind of Numeric'},
      invalid.attributes_errors
    )
  end

  class Config < Micro::Entity
    attribute :admin, accept: ->(value) { value == true || value == false }
  end

  class Account < Micro::Entity
    attribute :name, accept: String
    attribute :config, accept: Config
  end

  def test_nested_entity_coerces_hash
    account = Account.new(name: 'Rodrigo', config: { admin: true })

    assert_kind_of(Config, account.config)
    assert_equal(true, account.config.admin)
    refute_predicate(account, :attributes_errors?)
  end

  def test_nested_entity_accepts_instance
    config = Config.new(admin: false)
    account = Account.new(name: 'Rodrigo', config: config)

    assert_same(config, account.config)
    refute_predicate(account, :attributes_errors?)
  end

  def test_nested_entity_rejects_non_hash_non_entity
    account = Account.new(name: 'Rodrigo', config: 'oops')

    assert_predicate(account, :attributes_errors?)
    assert_match(/expected to be a kind of/, account.attributes_errors['config'])
  end

  class Order < Micro::Entity
    attribute :id, accept: Integer

    attribute :customer do
      attribute :name, accept: String
      attribute :email, accept: String
    end
  end

  def test_block_form_defines_nested_entity_at_runtime
    order = Order.new(id: 1, customer: { name: 'Rodrigo', email: 'a@b.com' })

    assert_kind_of(Micro::Entity, order.customer)
    assert_equal('Rodrigo', order.customer.name)
    assert_equal('a@b.com', order.customer.email)
    refute_predicate(order, :attributes_errors?)
  end

  def test_block_form_validates_nested_attributes
    order = Order.new(id: 1, customer: { name: :rodrigo, email: 'a@b.com' })

    assert_predicate(order.customer, :attributes_errors?)
    assert_equal(
      {'name' => 'expected to be a kind of String'},
      order.customer.attributes_errors
    )
  end

  class Profile < Micro::Entity
    attribute :nickname, accept: String, default: 'anon'
  end

  class Member < Micro::Entity
    attribute :profile, accept: Profile
  end

  def test_nested_entity_uses_defaults_when_hash_omits_keys
    member = Member.new(profile: {})

    assert_equal('anon', member.profile.nickname)
  end

  class StrictUser < Micro::Entity::Strict
    attribute :name, accept: String
    attribute :age, accept: Numeric
  end

  def test_strict_requires_all_attributes
    error = assert_raises(ArgumentError) { StrictUser.new(name: 'Rodrigo') }
    assert_match(/missing keyword: :age/, error.message)
  end

  def test_strict_raises_on_accept_errors
    error = assert_raises(ArgumentError) { StrictUser.new(name: :rodrigo, age: '34') }
    assert_match(/One or more attributes were rejected/, error.message)
  end

  def test_strict_succeeds_with_valid_input
    user = StrictUser.new(name: 'Rodrigo', age: 34)

    assert_equal('Rodrigo', user.name)
    assert_equal(34, user.age)
  end

  # Regression: in a multi-level subclass, the inline (block-form) nested
  # entity must NOT inherit parent classes' user-defined attributes.
  class ParentEntity < Micro::Entity
    attribute :shared, accept: String
  end

  class ChildEntity < ParentEntity
    attribute :nested do
      attribute :only_here, accept: String
    end
  end

  def test_block_form_does_not_inherit_parent_user_attributes
    nested_class = ChildEntity.__attributes_data__['nested'][1][1]

    assert_equal(['only_here'], nested_class.attributes,
                 'inline nested class must contain only its own block attributes')

    child = ChildEntity.new(shared: 'top', nested: { only_here: 'leaf' })

    assert_equal('top', child.shared)
    assert_equal('leaf', child.nested.only_here)
    refute_respond_to(child.nested, :shared, 'inline nested must not expose parent reader')
  end

  # Regression: even through a multi-level Strict chain, the inline nested
  # entity must remain Strict (feature-mix propagates) — but still without
  # the parent's user attributes (no leak).
  class StrictParentEntity < Micro::Entity::Strict
    attribute :shared, accept: String
  end

  class StrictChildEntity < StrictParentEntity
    attribute :nested do
      attribute :only_here, accept: String
    end
  end

  def test_block_form_propagates_strict_through_multi_level_chain
    nested_class = StrictChildEntity.__attributes_data__['nested'][1][1]

    assert_operator(nested_class, :<, Micro::Entity::Strict,
                    'inline child must inherit Strict feature-mix')
    assert_equal(['only_here'], nested_class.attributes,
                 'inline nested class must contain only its own block attributes')

    error = assert_raises(ArgumentError) do
      StrictChildEntity.new(shared: 'top', nested: {})
    end
    assert_match(/missing keyword: :only_here/, error.message)
  end

  # ---- block-form ordering tests ----
  # The `__entity_block_parent__` walker picks the nearest ancestor with
  # no user attributes. Regardless of where the block appears in the
  # class body, the inline class must contain ONLY the attributes declared
  # in the block.

  class BlockFirstThenSibling < Micro::Entity
    attribute :nested do
      attribute :only_here, accept: String
    end

    attribute :added_after, accept: String
  end

  class SiblingFirstThenBlock < Micro::Entity
    attribute :added_before, accept: String

    attribute :nested do
      attribute :only_here, accept: String
    end
  end

  def test_block_form_isolation_when_block_comes_before_siblings
    nested_class = BlockFirstThenSibling.__attributes_data__['nested'][1][1]
    assert_equal(['only_here'], nested_class.attributes,
                 'block-first: nested must not capture later sibling attrs')

    obj = BlockFirstThenSibling.new(added_after: 'A', nested: { only_here: 'L' })
    assert_equal('A', obj.added_after)
    assert_equal('L', obj.nested.only_here)
    refute_respond_to(obj.nested, :added_after, 'no leak from later sibling')
  end

  def test_block_form_isolation_when_block_comes_after_siblings
    nested_class = SiblingFirstThenBlock.__attributes_data__['nested'][1][1]
    assert_equal(['only_here'], nested_class.attributes,
                 'sibling-first: nested must not inherit earlier sibling attrs')

    obj = SiblingFirstThenBlock.new(added_before: 'B', nested: { only_here: 'L' })
    assert_equal('B', obj.added_before)
    assert_equal('L', obj.nested.only_here)
    refute_respond_to(obj.nested, :added_before, 'no leak from earlier sibling')
  end

  # Block form on a class that itself inherits from a class WITH attributes:
  # walker must skip past the with-attrs ancestor and land on `Micro::Entity`.
  class GrandparentEntity < Micro::Entity
    attribute :gp_attr, accept: String
  end

  class ParentInChain < GrandparentEntity
    attribute :p_attr, accept: String
  end

  class ChildInChain < ParentInChain
    attribute :nested do
      attribute :only_here, accept: String
    end
  end

  def test_block_form_walks_through_full_inheritance_chain
    nested_class = ChildInChain.__attributes_data__['nested'][1][1]
    assert_equal(['only_here'], nested_class.attributes,
                 'must skip past parent AND grandparent attrs')

    child = ChildInChain.new(gp_attr: 'g', p_attr: 'p', nested: { only_here: 'L' })
    assert_equal('g', child.gp_attr)
    assert_equal('p', child.p_attr)
    assert_equal('L', child.nested.only_here)
    refute_respond_to(child.nested, :gp_attr, 'no grandparent leak')
    refute_respond_to(child.nested, :p_attr,  'no parent leak')
  end

  # Regression for E4: anonymous inline classes used to render as
  # `#<Class:0x000000012345>` in `attributes_errors` because Accept's
  # `KindOf.accept_failed` interpolates the class directly. The new
  # singleton `to_s` makes the rejection message stable and readable.
  class HostForInlineNaming < Micro::Entity
    attribute :customer do
      attribute :name, accept: String
    end
  end

  def test_inline_block_form_class_has_stable_name_in_error_messages
    obj = HostForInlineNaming.new(customer: 'not a hash')

    assert_predicate(obj, :attributes_errors?)
    error = obj.attributes_errors['customer']

    refute_match(/0x[0-9a-f]+/, error,
                 'rejection message must not leak object address')
    assert_match(/HostForInlineNaming\(customer\)/, error,
                 'rejection message names the outer class and attribute')
  end

  # Regression for E1: when a user mixes `Micro::Attributes.with(:keys_as_symbol)`
  # (or similar feature includes) onto an Entity subclass, the inline (block-form)
  # nested entity does NOT inherit that mix — the parent picker only
  # propagates Strict-ness. Documented tradeoff; this test pins the contract
  # so a refactor of `__entity_block_parent__` can't silently regress it.
  class HostWithSymbolKeys < Micro::Entity
    include Micro::Attributes.with(:keys_as_symbol)

    attribute :outer, accept: String

    attribute :inline do
      attribute :inner, accept: String
    end
  end

  def test_block_form_does_not_inherit_intermediate_feature_includes
    host = HostWithSymbolKeys.new(outer: 'a', inline: { inner: 'b' })

    # The host class has KeysAsSymbol → its own attributes hash uses symbols.
    assert(host.attributes.key?(:outer), 'outer uses symbol key')
    refute(host.attributes.key?('outer'), 'outer does NOT use string key')

    # The inline class is rebuilt from `Micro::Entity` (gem base) and does
    # NOT receive KeysAsSymbol — its attributes hash uses string keys.
    assert(host.inline.attributes.key?('inner'),
           'inline child uses default (string) keys')
    refute(host.inline.attributes.key?(:inner),
           'inline child did NOT inherit KeysAsSymbol from host')
  end

  # ---- `Micro::Entity.with(...)` class macro ----
  # Sugar for `include Micro::Attributes.with(...)`. Must work identically
  # to the longer form, including the documented "intermediate feature
  # includes don't propagate to inline children" tradeoff.

  class WithSymbolKeys < Micro::Entity
    with :keys_as_symbol

    attribute :name, accept: String
  end

  def test_with_macro_single_symbol_feature
    obj = WithSymbolKeys.new(name: 'Rodrigo')

    assert_equal('Rodrigo', obj.name)
    assert(obj.attributes.key?(:name), 'KeysAsSymbol applied via with')
    refute(obj.attributes.key?('name'), 'no string-key fallback')
  end

  def test_with_macro_is_equivalent_to_include_long_form
    long_form = Class.new(Micro::Entity) do
      include Micro::Attributes.with(:keys_as_symbol)
      attribute :name, accept: String
    end

    long_obj = long_form.new(name: 'Rodrigo')
    short_obj = WithSymbolKeys.new(name: 'Rodrigo')

    assert_equal(long_obj.attributes, short_obj.attributes)
    assert_equal(long_form.attributes_access, WithSymbolKeys.attributes_access)
  end

  class WithStrictInit < Micro::Entity
    with initialize: :strict

    attribute :name, accept: String
    attribute :age,  accept: Numeric
  end

  def test_with_macro_hash_form_for_strict_variants
    err = assert_raises(ArgumentError) { WithStrictInit.new(name: 'X') }
    assert_match(/missing keyword: :age/, err.message)

    obj = WithStrictInit.new(name: 'X', age: 1)
    assert_equal('X', obj.name)
    assert_equal(1, obj.age)
  end

  class WithMixed < Micro::Entity
    with :keys_as_symbol, initialize: :strict

    attribute :name, accept: String
    attribute :age,  accept: Numeric
  end

  def test_with_macro_combines_positional_and_hash_args
    err = assert_raises(ArgumentError) { WithMixed.new(name: 'X') }
    assert_match(/missing keyword: :age/, err.message,
                 'strict init applied')

    obj = WithMixed.new(name: 'X', age: 1)
    assert(obj.attributes.key?(:name), 'symbol keys applied')
  end

  class WithMultipleCalls < Micro::Entity
    with :keys_as_symbol
    with initialize: :strict

    attribute :name, accept: String
    attribute :age,  accept: Numeric
  end

  def test_with_macro_multiple_calls_accumulate
    err = assert_raises(ArgumentError) { WithMultipleCalls.new(name: 'X') }
    assert_match(/missing keyword: :age/, err.message,
                 'second with call layered strict on top')

    obj = WithMultipleCalls.new(name: 'X', age: 1)
    assert(obj.attributes.key?(:name), 'first with call still effective')
  end

  # ---- with + block-form attribute interactions ----

  class WithMacroAndBlockForm < Micro::Entity
    with :keys_as_symbol

    attribute :outer, accept: String

    attribute :inline do
      attribute :inner, accept: String
    end
  end

  def test_with_macro_then_block_form_does_not_propagate_features
    host = WithMacroAndBlockForm.new(outer: 'o', inline: { inner: 'i' })

    # Outer reflects KeysAsSymbol (symbol keys).
    assert(host.attributes.key?(:outer), 'outer uses symbol keys')

    # Inline child does NOT inherit KeysAsSymbol — same documented
    # tradeoff as the `include Micro::Attributes.with(...)` long form.
    assert(host.inline.attributes.key?('inner'),
           'inline child uses string keys despite outer with :keys_as_symbol')
    refute(host.inline.attributes.key?(:inner))
  end

  class WithStrictAndBlockForm < Micro::Entity
    with initialize: :strict

    attribute :name, accept: String

    attribute :inline do
      attribute :inner, accept: String
    end
  end

  def test_with_macro_strict_does_not_propagate_strict_to_block_form_child
    # Outer is strict — missing :inline raises.
    err = assert_raises(ArgumentError) { WithStrictAndBlockForm.new(name: 'X') }
    assert_match(/missing keyword/, err.message)

    # But the inline child is built from `Micro::Entity` (gem base loose),
    # NOT from `Micro::Entity::Strict`. `with initialize: :strict` includes
    # the strict variants on `self`, but `__entity_block_parent__` only
    # routes to Strict when `self <= Micro::Entity::Strict` (class
    # inheritance, not include).
    obj = WithStrictAndBlockForm.new(name: 'X', inline: {})
    refute_nil(obj.inline)
    assert_nil(obj.inline.inner, 'inline allows missing keys — loose by design')
  end

  # `class Foo < Micro::Entity::Strict` propagates strict to block-form
  # children, but `class Foo < Micro::Entity; with initialize: :strict`
  # does NOT. This asymmetry is the documented tradeoff; pin it here so
  # nobody accidentally collapses the two paths.
  def test_subclass_strict_vs_with_strict_have_different_block_form_semantics
    # Subclass-of-Strict path: inline child IS strict.
    subclass_form = Class.new(Micro::Entity::Strict) do
      attribute :inline do
        attribute :inner, accept: String
      end
    end
    err = assert_raises(ArgumentError) do
      subclass_form.new(inline: {})
    end
    assert_match(/missing keyword/, err.message)

    # with(initialize: :strict) path: inline child is loose.
    with_form = Class.new(Micro::Entity) do
      with initialize: :strict
      attribute :inline do
        attribute :inner, accept: String
      end
    end
    # Doesn't raise — inline allows missing inner.
    obj = with_form.new(inline: {})
    assert_nil(obj.inline.inner)
  end

  # ---- Deep nesting (3 levels) ----
  # Both class-based and block-based composition must work recursively.
  # Errors are mirrored as a `'is invalid'` marker at each ancestor;
  # the leaf retains the detail. ActiveModel `valid?` also bubbles.

  class AcceptLeaf < Micro::Entity
    attribute :city, accept: String
  end

  class AcceptMid < Micro::Entity
    attribute :leaf, accept: AcceptLeaf
  end

  class AcceptRoot < Micro::Entity
    attribute :mid, accept: AcceptMid
  end

  def test_class_based_deep_nesting_happy_path
    root = AcceptRoot.new(mid: { leaf: { city: 'Rio' } })

    assert_kind_of(AcceptMid,  root.mid)
    assert_kind_of(AcceptLeaf, root.mid.leaf)
    assert_equal('Rio', root.mid.leaf.city)
    refute_predicate(root, :attributes_errors?)
    refute_predicate(root.mid, :attributes_errors?)
    refute_predicate(root.mid.leaf, :attributes_errors?)
  end

  def test_class_based_deep_nesting_bubbles_accept_errors_to_root
    root = AcceptRoot.new(mid: { leaf: { city: 42 } })

    # Detail lives at the leaf.
    assert_predicate(root.mid.leaf, :attributes_errors?)
    assert_match(/kind of String/, root.mid.leaf.attributes_errors['city'])

    # Markers bubble up.
    assert_predicate(root.mid, :attributes_errors?, 'mid mirrors child invalidity')
    assert_equal('is invalid', root.mid.attributes_errors['leaf'])

    assert_predicate(root, :attributes_errors?, 'root mirrors grandchild invalidity')
    assert_equal('is invalid', root.attributes_errors['mid'])
  end

  class BlockDeepRoot < Micro::Entity
    attribute :mid do
      attribute :leaf do
        attribute :city, accept: String
      end
    end
  end

  def test_block_based_deep_nesting_happy_path
    root = BlockDeepRoot.new(mid: { leaf: { city: 'Rio' } })

    assert_equal('Rio', root.mid.leaf.city)
    refute_predicate(root, :attributes_errors?)
  end

  def test_block_based_deep_nesting_bubbles_accept_errors_to_root
    root = BlockDeepRoot.new(mid: { leaf: { city: 42 } })

    assert_predicate(root.mid.leaf, :attributes_errors?, 'leaf has the detail')
    assert_match(/kind of String/, root.mid.leaf.attributes_errors['city'])

    assert_predicate(root.mid, :attributes_errors?, 'mid mirrors child')
    assert_predicate(root, :attributes_errors?, 'root mirrors grandchild')
  end

  if ENTITY_TEST_HAS_ACTIVEMODEL = (begin; require 'active_model'; true; rescue LoadError; false; end)
    class AMDeepLeaf < Micro::Entity
      with :activemodel_validations
      attribute :name, accept: String, validates: { presence: true }
    end

    class AMDeepMid < Micro::Entity
      with :activemodel_validations
      attribute :leaf, accept: AMDeepLeaf
    end

    class AMDeepRoot < Micro::Entity
      with :activemodel_validations
      attribute :mid, accept: AMDeepMid
    end

    def test_am_deep_nesting_valid_for_well_formed_tree
      root = AMDeepRoot.new(mid: { leaf: { name: 'Rodrigo' } })

      assert_predicate(root, :valid?)
      assert_predicate(root.mid, :valid?)
      assert_predicate(root.mid.leaf, :valid?)
    end

    def test_am_deep_nesting_root_valid_returns_false_when_leaf_fails_presence
      root = AMDeepRoot.new(mid: { leaf: { name: '' } })

      # Leaf has the detail.
      refute_predicate(root.mid.leaf, :valid?, 'leaf is invalid')
      assert_includes(root.mid.leaf.errors[:name].map(&:to_s).join, "can't be blank")

      # Mid mirrors leaf invalidity.
      refute_predicate(root.mid, :valid?, 'mid mirrors leaf invalidity')
      assert_includes(root.mid.errors[:leaf].map(&:to_s).join, 'is invalid')

      # Root mirrors grandchild invalidity.
      refute_predicate(root, :valid?, 'root mirrors grandchild invalidity')
      assert_includes(root.errors[:mid].map(&:to_s).join, 'is invalid')
    end

    # Mixed tree: AM on root, accept-only on mid/leaf. The AM root's
    # validator must still detect descendant invalidity by falling back
    # to `attributes_errors?` for children without `valid?`.
    class MixedLeafAccept < Micro::Entity
      attribute :name, accept: String
    end

    class MixedRootAM < Micro::Entity
      with :activemodel_validations
      attribute :leaf, accept: MixedLeafAccept
    end

    def test_am_root_with_accept_only_leaf_propagates
      good = MixedRootAM.new(leaf: { name: 'OK' })
      assert_predicate(good, :valid?)

      bad = MixedRootAM.new(leaf: { name: 42 })
      refute_predicate(bad, :valid?,
                       'AM-only root must still bubble accept-error leaves')
      assert_includes(bad.errors[:leaf].map(&:to_s).join, 'is invalid')
    end
  end
end
