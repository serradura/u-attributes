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
  end
end
