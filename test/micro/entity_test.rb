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
end
