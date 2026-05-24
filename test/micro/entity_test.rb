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
end
