require 'test_helper'

# Exercises composition behavior baked into `Micro::Attributes` itself —
# block-form `attribute :foo do ... end`, hash → child-instance coercion,
# deep validation bubbling. The same behavior is available via both API
# entry points:
#
#   class Foo
#     include Micro::Attributes.with(initialize: true, accept: true)
#     ...
#   end
#
#   Foo = Micro::Attributes.new do
#     ...
#   end
#
# Most tests exercise the second form because it's terser; the first form
# is exercised wherever it differs (KeysAsSymbol, AM, etc.).
class Micro::Attributes::CompositionTest < Minitest::Test
  # ---------- basic init ----------

  Person = Micro::Attributes.new do
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

  # ---------- accept validations ----------

  User = Micro::Attributes.new do
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

  # ---------- nested via accept: (hash coercion) ----------

  Config = Micro::Attributes.new do
    attribute :admin, accept: ->(value) { value == true || value == false }
  end

  Account = Micro::Attributes.new do
    attribute :name, accept: String
    attribute :config, accept: Config
  end

  def test_nested_via_accept_coerces_hash
    account = Account.new(name: 'Rodrigo', config: { admin: true })

    assert_kind_of(Config, account.config)
    assert_equal(true, account.config.admin)
    refute_predicate(account, :attributes_errors?)
  end

  def test_nested_via_accept_passes_through_instance
    config = Config.new(admin: false)
    account = Account.new(name: 'Rodrigo', config: config)

    assert_same(config, account.config)
    refute_predicate(account, :attributes_errors?)
  end

  def test_nested_via_accept_rejects_non_hash_non_instance
    account = Account.new(name: 'Rodrigo', config: 'oops')
    assert_predicate(account, :attributes_errors?)
    assert_match(/expected to be a kind of/, account.attributes_errors['config'])
  end

  # ---------- block-form (anonymous inline class) ----------

  Order = Micro::Attributes.new do
    attribute :id, accept: Integer

    attribute :customer do
      attribute :name, accept: String
      attribute :email, accept: String
    end
  end

  def test_block_form_defines_nested_at_runtime
    order = Order.new(id: 1, customer: { name: 'Rodrigo', email: 'a@b.com' })

    assert(order.customer.class.include?(Micro::Attributes))
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

  Profile = Micro::Attributes.new do
    attribute :nickname, accept: String, default: 'anon'
  end

  Member = Micro::Attributes.new do
    attribute :profile, accept: Profile
  end

  def test_nested_uses_defaults_when_hash_omits_keys
    member = Member.new(profile: {})
    assert_equal('anon', member.profile.nickname)
  end

  # ---------- strict variant ----------

  StrictUser = Micro::Attributes.new(initialize: :strict, accept: :strict) do
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

  # ---------- multi-level subclass: child does not leak attrs into block-form inline ----------

  class ParentEntity
    include Micro::Attributes.with(initialize: true, accept: true)
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

  # ---------- block-form ordering ----------

  class BlockFirstThenSibling
    include Micro::Attributes.with(initialize: true, accept: true)

    attribute :nested do
      attribute :only_here, accept: String
    end

    attribute :added_after, accept: String
  end

  class SiblingFirstThenBlock
    include Micro::Attributes.with(initialize: true, accept: true)

    attribute :added_before, accept: String

    attribute :nested do
      attribute :only_here, accept: String
    end
  end

  def test_block_form_isolation_when_block_comes_before_siblings
    nested_class = BlockFirstThenSibling.__attributes_data__['nested'][1][1]
    assert_equal(['only_here'], nested_class.attributes)

    obj = BlockFirstThenSibling.new(added_after: 'A', nested: { only_here: 'L' })
    assert_equal('A', obj.added_after)
    assert_equal('L', obj.nested.only_here)
    refute_respond_to(obj.nested, :added_after)
  end

  def test_block_form_isolation_when_block_comes_after_siblings
    nested_class = SiblingFirstThenBlock.__attributes_data__['nested'][1][1]
    assert_equal(['only_here'], nested_class.attributes)

    obj = SiblingFirstThenBlock.new(added_before: 'B', nested: { only_here: 'L' })
    assert_equal('B', obj.added_before)
    assert_equal('L', obj.nested.only_here)
    refute_respond_to(obj.nested, :added_before)
  end

  # ---------- E4 regression: stable inline-class name in error messages ----------

  class HostForInlineNaming
    include Micro::Attributes.with(initialize: true, accept: true)

    attribute :customer do
      attribute :name, accept: String
    end
  end

  def test_inline_block_form_class_has_stable_name_in_error_messages
    obj = HostForInlineNaming.new(customer: 'not a hash')

    assert_predicate(obj, :attributes_errors?)
    error = obj.attributes_errors['customer']

    refute_match(/0x[0-9a-f]+/, error, 'rejection message must not leak object address')
    assert_match(/HostForInlineNaming\(customer\)/, error,
                 'rejection message names the outer class and attribute')
  end

  # ---------- the `with` class macro ----------

  class WithMacroSym
    include Micro::Attributes.with(initialize: true, accept: true)
    with :keys_as_symbol
    attribute :name, accept: String
  end

  def test_with_macro_layers_feature
    obj = WithMacroSym.new(name: 'Rodrigo')
    assert(obj.attributes.key?(:name))
    refute(obj.attributes.key?('name'))
  end

  class WithMacroStrict
    include Micro::Attributes.with(initialize: true, accept: true)
    with initialize: :strict
    attribute :name, accept: String
    attribute :age, accept: Numeric
  end

  def test_with_macro_strict_layer
    err = assert_raises(ArgumentError) { WithMacroStrict.new(name: 'X') }
    assert_match(/missing keyword: :age/, err.message)
  end

  # ---------- inline child propagates outer feature mix ----------

  HostWithSymbolKeys = Micro::Attributes.new(keys_as: :symbol) do
    attribute :outer, accept: String

    attribute :inline do
      attribute :inner, accept: String
    end
  end

  def test_block_form_propagates_outer_feature_mix_to_inline_child
    host = HostWithSymbolKeys.new(outer: 'a', inline: { inner: 'b' })

    # Outer reflects KeysAsSymbol (symbol keys).
    assert(host.attributes.key?(:outer))
    refute(host.attributes.key?('outer'))

    # Inline child ALSO uses KeysAsSymbol now (the with-module is reused).
    assert(host.inline.attributes.key?(:inner),
           'inline child inherits the outer feature mix')
    refute(host.inline.attributes.key?('inner'))
  end

  HostStrict = Micro::Attributes.new(initialize: :strict, accept: :strict) do
    attribute :outer, accept: String

    attribute :inline do
      attribute :inner, accept: String
    end
  end

  def test_block_form_propagates_strict_to_inline_child
    err = assert_raises(ArgumentError) { HostStrict.new(outer: 'X', inline: {}) }
    assert_match(/missing keyword: :inner/, err.message,
                 'inline child also strict — missing :inner raises')
  end

  # ---------- deep nesting (3 levels) ----------

  AcceptLeaf = Micro::Attributes.new do
    attribute :city, accept: String
  end

  AcceptMid = Micro::Attributes.new do
    attribute :leaf, accept: AcceptLeaf
  end

  AcceptRoot = Micro::Attributes.new do
    attribute :mid, accept: AcceptMid
  end

  def test_class_based_deep_nesting_happy_path
    root = AcceptRoot.new(mid: { leaf: { city: 'Rio' } })
    assert_kind_of(AcceptMid, root.mid)
    assert_kind_of(AcceptLeaf, root.mid.leaf)
    assert_equal('Rio', root.mid.leaf.city)
    refute_predicate(root, :attributes_errors?)
  end

  def test_class_based_deep_nesting_bubbles_accept_errors_to_root
    root = AcceptRoot.new(mid: { leaf: { city: 42 } })

    assert_predicate(root.mid.leaf, :attributes_errors?)
    assert_match(/kind of String/, root.mid.leaf.attributes_errors['city'])

    assert_predicate(root.mid, :attributes_errors?)
    assert_equal('is invalid', root.mid.attributes_errors['leaf'])

    assert_predicate(root, :attributes_errors?)
    assert_equal('is invalid', root.attributes_errors['mid'])
  end

  BlockDeepRoot = Micro::Attributes.new do
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

    assert_predicate(root.mid.leaf, :attributes_errors?)
    assert_match(/kind of String/, root.mid.leaf.attributes_errors['city'])
    assert_predicate(root.mid, :attributes_errors?)
    assert_predicate(root, :attributes_errors?)
  end

  if begin; require 'active_model'; true; rescue LoadError; false; end
    AMDeepLeaf = Micro::Attributes.new(active_model: :validations) do
      attribute :name, accept: String, validates: { presence: true }
    end

    AMDeepMid = Micro::Attributes.new(active_model: :validations) do
      attribute :leaf, accept: AMDeepLeaf
    end

    AMDeepRoot = Micro::Attributes.new(active_model: :validations) do
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

      refute_predicate(root.mid.leaf, :valid?)
      assert_includes(root.mid.leaf.errors[:name].map(&:to_s).join, "can't be blank")

      refute_predicate(root.mid, :valid?)
      assert_includes(root.mid.errors[:leaf].map(&:to_s).join, 'is invalid')

      refute_predicate(root, :valid?)
      assert_includes(root.errors[:mid].map(&:to_s).join, 'is invalid')
    end

    MixedLeafAccept = Micro::Attributes.new do
      attribute :name, accept: String
    end

    MixedRootAM = Micro::Attributes.new(active_model: :validations) do
      attribute :leaf, accept: MixedLeafAccept
    end

    def test_am_root_with_accept_only_leaf_propagates
      good = MixedRootAM.new(leaf: { name: 'OK' })
      assert_predicate(good, :valid?)

      bad = MixedRootAM.new(leaf: { name: 42 })
      refute_predicate(bad, :valid?)
      assert_includes(bad.errors[:leaf].map(&:to_s).join, 'is invalid')
    end

    # Regression M3: block-form inline class in an AM host must NOT raise
    # `"Class name cannot be blank"` when `errors.full_messages` (or any
    # other path that consults `klass.model_name`) is invoked. The fix
    # is to override `model_name` on the inline class with an explicit
    # name string.
    AMBlockFormHost = Micro::Attributes.new(active_model: :validations) do
      attribute :address do
        attribute :street, accept: String, validates: { presence: true }
      end
    end

    def test_am_renders_error_messages_for_block_form_nested
      obj = AMBlockFormHost.new(address: { street: '' })

      # The validate-then-render chain must not raise.
      messages = obj.errors.full_messages
      assert_kind_of(Array, messages, 'errors.full_messages must not raise')

      # The inline child also must be inspectable without raising.
      child_messages = obj.address.errors.full_messages
      assert_kind_of(Array, child_messages)
      assert(child_messages.any? { |m| m.include?("can't be blank") },
             'leaf retains the original AM message')
    end
  end

  # ---- Regression Co3: Coercion gate is arity-based, not feature-based ----

  # User-defined hash constructor (the long-standing u-case v4 idiom).
  # The class includes `Micro::Attributes` directly (no Initialize feature)
  # but writes its own `initialize` that delegates to `attributes=`.
  class InnerUserCtor
    include Micro::Attributes
    attribute :a

    def initialize(arg)
      self.attributes = arg
    end
  end

  OuterUserCtorTarget = Micro::Attributes.new do
    attribute :inner, accept: InnerUserCtor
  end

  def test_coercion_fires_for_user_defined_hash_constructors
    # Arity-based gate: `InnerUserCtor`'s `initialize(arg)` has arity 1,
    # so Coercion fires and turns the hash into an instance — the
    # u-case v4 idiom still works.
    obj = OuterUserCtorTarget.new(inner: { a: 1 })
    assert_kind_of(InnerUserCtor, obj.inner)
    assert_equal(1, obj.inner.instance_variable_get(:@a))
    refute_predicate(obj, :attributes_errors?)

    # Already-built instances pass through unchanged.
    pre_built = InnerUserCtor.new(a: 2)
    obj2 = OuterUserCtorTarget.new(inner: pre_built)
    assert_same(pre_built, obj2.inner)
  end

  # Target with NO custom constructor (Object#initialize, arity 0) — the
  # gate skips Coercion, hash passes through, accept's KindOf rejects.
  class InnerNoConstructor
    include Micro::Attributes
    attribute :a
  end

  OuterNoCtorTarget = Micro::Attributes.new do
    attribute :inner, accept: InnerNoConstructor
  end

  def test_coercion_skips_when_target_initialize_is_arity_zero
    bad = OuterNoCtorTarget.new(inner: { a: 1 })
    assert_predicate(bad, :attributes_errors?,
                     'no coerce → accept KindOf rejects the raw Hash')
    assert_match(/kind of/, bad.attributes_errors['inner'])
  end

  # ---- Regression X1: Micro::Attributes.new(initialize: false) is rejected ----

  def test_factory_rejects_initialize_false
    err = assert_raises(ArgumentError) do
      Micro::Attributes.new(initialize: false) { attribute :name }
    end
    assert_match(/requires the :initialize feature/, err.message)
  end

  def test_factory_still_accepts_initialize_strict_and_true
    # Sanity — these should NOT raise.
    Micro::Attributes.new(initialize: true)  { attribute :name }
    Micro::Attributes.new(initialize: :strict) { attribute :name }
  end

  # Round-2 regression: the factory guard must catch `nil` and garbage
  # values too, not just `false`. Pre-fix only `== false` was checked,
  # so `initialize: nil` slipped through and produced a class with no
  # hash constructor.
  def test_factory_rejects_initialize_nil
    err = assert_raises(ArgumentError) do
      Micro::Attributes.new(initialize: nil) { attribute :name }
    end
    assert_match(/requires the :initialize feature/, err.message)
  end

  def test_factory_rejects_initialize_garbage_value
    err = assert_raises(ArgumentError) do
      Micro::Attributes.new(initialize: 'on') { attribute :name }
    end
    assert_match(/requires the :initialize feature/, err.message)
  end

  # Round-2 regression: instance `inspect` must NOT leak the anonymous
  # inline class's heap address. The fix overrides `inspect` on the
  # inline class to use `self.class.to_s` (already stable) instead of
  # `Object#inspect`'s address form.
  ProductHost = Micro::Attributes.new do
    attribute :address do
      attribute :city, accept: String
    end
  end

  def test_inline_instance_inspect_does_not_leak_heap_address
    obj = ProductHost.new(address: { city: 'Rio' })

    inspected = obj.address.inspect

    refute_match(/0x[0-9a-f]+/, inspected,
                 'instance inspect must not leak heap address')
    assert_match(/ProductHost\(address\)/, inspected,
                 'instance inspect uses the stable class label')
  end

  # Round-2 regression for the "u-case impact": when the host class
  # includes `Micro::Attributes` (or `Features::*`) DIRECTLY without
  # going through `Micro::Attributes.with(...)`, block-form inline
  # children must still get the `:initialize` and `:accept` defaults
  # so hash coercion works.
  class UCaseLikeHost
    include Micro::Attributes  # no .with(...)

    attribute :customer do
      attribute :name, accept: String
    end

    def initialize(arg)
      self.attributes = arg
    end
  end

  def test_block_form_inline_works_when_host_lacks_with_module
    obj = UCaseLikeHost.new(customer: { name: 'Alice' })

    # Pre-fix: customer would be a raw Hash; `obj.customer.name` would
    # NoMethodError. Post-fix: customer is coerced to the inline class
    # (which has :initialize+:accept defaults).
    refute_kind_of(Hash, obj.customer)
    assert_equal('Alice', obj.customer.name)
  end

  if begin; require 'active_model'; true; rescue LoadError; false; end
    # Round-2 regression for M3 (AM load order): the `model_name`
    # singleton must work even when AM is required AFTER the inline
    # class is built — the check is at CALL time, not build time.
    LateAMHost = Micro::Attributes.new(active_model: :validations) do
      attribute :address do
        attribute :street, accept: String, validates: { presence: true }
      end
    end

    def test_inline_model_name_resolves_lazily_for_late_loaded_am
      # AM was loaded before this test runs (since the guard
      # `require 'active_model'` succeeded), so we don't actually have
      # a way to simulate "AM loaded after class creation" in-process —
      # but we can verify the singleton method is defined unconditionally
      # and produces a valid `ActiveModel::Name` when AM is present.
      inline_class = LateAMHost.__attributes_data__['address'][1][1]

      assert_respond_to(inline_class, :model_name,
                        'model_name singleton always defined (not gated at build time)')

      name = inline_class.model_name
      assert_kind_of(ActiveModel::Name, name)
      assert_match(/LateAMHost\(address\)/, name.name)
    end
  end

  # Round-2 regression for Accept's reject path: private/protected
  # attribute names must NOT leak through `attributes_errors` even when
  # Accept's own reject (not the Coercion bubble) is what would write.
  class PrivateAcceptHost
    include Micro::Attributes.with(:initialize, :accept)
    attribute :secret, accept: String, private: true
  end

  def test_accept_reject_does_not_leak_private_attr_key
    obj = PrivateAcceptHost.new(secret: 42)

    refute(obj.attributes_errors.key?('secret'),
           'Accept reject must not leak private attr key (string)')
    refute(obj.attributes_errors.key?(:secret),
           'Accept reject must not leak private attr key (symbol)')
    refute_predicate(obj, :attributes_errors?,
                     'private attr never contributes to attributes_errors')
  end

  # ---- Regression F1: layered with(...) reaches inline child ----

  class LayeredWith
    include Micro::Attributes.with(:initialize)
    include Micro::Attributes.with(:accept)
    attribute :name, accept: String

    attribute :child do
      attribute :inner, accept: String
    end
  end

  def test_layered_with_includes_apply_to_block_form_inline_class
    # Pre-fix: only the first include's With::* module was stored, so
    # the inline child missed `:accept`. Now we scan ancestors at
    # build time and replay every With::* module, so the inline child
    # gets BOTH Initialize and Accept.
    inline_klass = LayeredWith.__attributes_data__['child'][1][1]

    assert(inline_klass.ancestors.include?(Micro::Attributes::Features::Accept),
           'inline class includes Accept (from the layered include)')
    assert(inline_klass.ancestors.include?(Micro::Attributes::Features::Initialize),
           'inline class includes Initialize (from the first include)')

    # Practical check: an inline-child instance has Accept-feature methods.
    bad = LayeredWith.new(name: 'X', child: { inner: 42 })
    assert_predicate(bad.child, :attributes_errors?,
                     'inline child exposes Accept-feature `attributes_errors?`')
  end

  class WithMacroLayered
    include Micro::Attributes.with(:initialize)
    with :accept
    attribute :child do
      attribute :inner, accept: String
    end
  end

  def test_with_class_macro_layered_applies_to_inline_child
    bad = WithMacroLayered.new(child: { inner: 42 })
    assert_predicate(bad.child, :attributes_errors?,
                     'with-macro layered Accept reaches the inline child too')
  end

  # ---- Regression M1: anonymous host class — inline label resolves lazily ----

  def test_inline_label_resolves_after_constant_assignment
    # Build the class anonymously, then assign to a constant. The
    # inline child's `to_s` is captured lazily, so it picks up the
    # assigned name on first call (not the heap address).
    klass = Micro::Attributes.new do
      attribute :address do
        attribute :zip, accept: String
      end
    end

    # Before constant assignment, the host is anonymous — `to_s` falls
    # back to `outer.inspect` which is `"#<Class:0x...>"`.
    anon_inline_class = klass.__attributes_data__['address'][1][1]
    anon_repr = anon_inline_class.to_s
    assert_match(/0x[0-9a-f]+/, anon_repr,
                 'before constant assignment, falls back to address (expected)')

    # Assign to a constant — Ruby sets `klass.name`. The inline child's
    # `to_s` now resolves to "TestLazyHost(address)".
    self.class.const_set(:TestLazyHost, klass)
    refute_match(/0x[0-9a-f]+/, anon_inline_class.to_s,
                 'after constant assignment, label uses the new name')
    assert_match(/TestLazyHost\(address\)/, anon_inline_class.to_s)
  end

  # ---- Regression Co1: bubble does not leak private attr keys ----
  #
  # When a private nested-entity attribute receives a HASH that successfully
  # coerces into a child instance, Accept's KindOf check PASSES (the coerced
  # value IS a child instance), so Accept doesn't write to attributes_errors.
  # The only code path that could leak the private key into the parent's
  # attributes_errors is the Coercion BUBBLE — and the visibility gate
  # added in this PR prevents that.

  class PrivateNestedHost
    include Micro::Attributes.with(:initialize, :accept)
    attribute :secret_child, accept: AcceptLeaf, private: true
  end

  def test_bubble_does_not_leak_private_attr_into_attributes_errors
    # AcceptLeaf coerces from {} successfully but its `:city` (accept: String)
    # gets nil → child has its own attributes_errors. Pre-fix the bubble
    # would write 'secret_child' into the parent's attributes_errors,
    # leaking the private name. Post-fix the bubble is gated on visibility.
    obj = PrivateNestedHost.new(secret_child: {})

    # The coerced child does have errors (city is nil, not String).
    assert_predicate(obj.send(:secret_child), :attributes_errors?,
                     'child has its own errors (sanity)')

    # ...but the bubble must NOT surface the private key on the parent.
    refute(obj.attributes_errors.key?('secret_child'),
           'bubble must not write private attr key into attributes_errors')
    refute(obj.attributes_errors.key?(:secret_child),
           'bubble must not write private attr (symbol form either)')
  end

  # ---- Regression Co2: private attr name not leaked into AM errors ----

  if begin; require 'active_model'; true; rescue LoadError; false; end
    class PrivateNestedAMHost
      include Micro::Attributes.with(initialize: true, accept: true, active_model: :validations)
      attribute :secret, accept: AMDeepLeaf, private: true, default: { name: '' }
    end

    def test_validator_does_not_leak_private_attr_into_am_errors
      obj = PrivateNestedAMHost.new({})

      obj.valid?

      refute(obj.errors.key?(:secret),
             'private attr name must not appear in AM errors')
      assert_empty(obj.errors.full_messages.grep(/Secret/),
                   'private attr name must not appear in AM full_messages')
    end

    AMInspectHost = Micro::Attributes.new(active_model: :validations) do
      attribute :child do
        attribute :pub, accept: String, default: 'p', validates: { presence: true }
      end
    end

    def test_inline_inspect_hides_am_internals
      obj = AMInspectHost.new(child: { pub: 'x' })
      obj.child.valid?  # populate AM internals

      inspected = obj.child.inspect

      refute_match(/@errors/, inspected, 'AM @errors must not leak')
      refute_match(/@validation_context/, inspected, 'AM internals must not leak')
      refute_match(/@context_for_validation/, inspected, 'AM internals must not leak')
    end

    # Round-3 #7: model_name only defined when AM is included on the inline class
    HostWithoutAMForModelName = Micro::Attributes.new do
      attribute :child do
        attribute :x
      end
    end

    HostWithAMForModelName = Micro::Attributes.new(active_model: :validations) do
      attribute :child do
        attribute :x
      end
    end

    def test_inline_does_not_respond_to_model_name_when_host_lacks_am
      inline = HostWithoutAMForModelName.__attributes_data__['child'][1][1]
      refute_respond_to(inline, :model_name,
                        'no AM in inline → no model_name (duck-typing friendly)')
    end

    def test_inline_responds_to_model_name_when_host_has_am
      inline = HostWithAMForModelName.__attributes_data__['child'][1][1]
      assert_respond_to(inline, :model_name)

      name = inline.model_name
      assert_kind_of(ActiveModel::Name, name)
      assert_match(/HostWithAMForModelName\(child\)/, name.name)
    end
  end

  # ---- Round-3 #1: arity gate tightened ----

  class TwoArgCtor
    include Micro::Attributes
    attribute :a
    attribute :b
    def initialize(a, b)
      self.attributes = { a: a, b: b }
    end
  end

  OuterAvoidsCrash = Micro::Attributes.new do
    attribute :inner, accept: TwoArgCtor
  end

  def test_arity_gate_skips_multi_required_arg_constructors
    # Pre-fix: arity 2 != 0 → Coercion fires → klass.new(hash) raises.
    # Post-fix: arity 2 fails the gate → Coercion skips → KindOf rejects.
    bad = OuterAvoidsCrash.new(inner: { a: 1, b: 2 })

    assert_predicate(bad, :attributes_errors?,
                     'Coercion correctly skipped; accept KindOf rejected the Hash')
    assert_match(/kind of/, bad.attributes_errors['inner'])

    # Already-built instances still pass through.
    pre = TwoArgCtor.new(1, 2)
    obj = OuterAvoidsCrash.new(inner: pre)
    assert_same(pre, obj.inner)
  end

  class VariadicCtor
    include Micro::Attributes
    attribute :a
    def initialize(*args)
      self.attributes = args.first || {}
    end
  end

  OuterVariadic = Micro::Attributes.new do
    attribute :inner, accept: VariadicCtor
  end

  def test_arity_gate_allows_variadic_constructors
    obj = OuterVariadic.new(inner: { a: 1 })
    assert_kind_of(VariadicCtor, obj.inner)
    refute_predicate(obj, :attributes_errors?)
  end

  # ---- Round-3 #2: strict-accept raises for invalid private attr ----

  class StrictPrivateHost
    include Micro::Attributes.with(initialize: :strict, accept: :strict)
    attribute :name,   accept: String
    attribute :secret, accept: String, private: true
  end

  def test_strict_accept_raises_for_invalid_private_attr
    err = assert_raises(ArgumentError) do
      StrictPrivateHost.new(name: 'X', secret: 42)
    end
    assert_match(/One or more attributes were rejected/, err.message)
    assert_match(/private or protected attribute failed/, err.message,
                 'raise message notes hidden failure without leaking the name')
    refute_match(/secret/, err.message,
                 'private attribute name must NOT appear in raise message')
  end

  def test_strict_accept_passes_when_private_validation_succeeds
    obj = StrictPrivateHost.new(name: 'X', secret: 'sssh')
    assert_equal('X', obj.name)
  end

  def test_strict_accept_still_raises_for_public_attr_with_named_message
    err = assert_raises(ArgumentError) do
      StrictPrivateHost.new(name: :sym, secret: 'sssh')
    end
    assert_match(/"name" expected to be a kind of String/, err.message,
                 'public attr name still appears (only private is hidden)')
  end

  # ---- Round-3 #3+#4: inline inspect filters to public attrs ----

  HostWithInlineForInspect = Micro::Attributes.new do
    attribute :child do
      attribute :pub,    accept: String, default: 'p'
      attribute :secret, accept: String, default: 'sssh', private: true
    end
  end

  def test_inline_inspect_hides_private_attr_values
    obj = HostWithInlineForInspect.new(child: {})
    inspected = obj.child.inspect

    assert_match(/@pub="p"/, inspected, 'public attr surfaces in inspect')
    refute_match(/secret/, inspected,
                 'private attr name must not appear in inspect')
    refute_match(/sssh/, inspected,
                 'private attr value must not leak in inspect')
  end
end
