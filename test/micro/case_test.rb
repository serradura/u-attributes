require 'test_helper'

class Micro::AttributesTest < Minitest::Test
  class Add < Micro::Case
    attributes 'a', :b

    def call!
      Success result: { number: a + b }
    end
  end

  def test_add
    result = Add.call(a: 1, 'b' => 2)

    assert_predicate result, :success?
    assert_equal 3, result[:number]
  end

  class Subtract1 < Micro::Case
    attribute :a, required: true
    attribute 'b', default: 1

    def call!
      Success result: { number: a - b }
    end
  end

  def test_subtract1
    err = assert_raises(ArgumentError) { Subtract1.call }
    assert_equal('missing keyword: :a', err.message )

    # --

    result1 = Subtract1.call(a: 3, b: 2)

    assert_predicate result1, :success?
    assert_equal 1, result1[:number]

    result2 = Subtract1.call(a: 3)

    assert_predicate result2, :success?
    assert_equal 2, result2[:number]
  end

  class Subtract2 < Micro::Case::Strict
    attribute :a
    attribute 'b', default: 2

    def call!
      Success result: { number: a - b }
    end
  end

  def test_subtract2
    err = assert_raises(ArgumentError) { Subtract2.call }
    assert_equal('missing keyword: :a', err.message )

    # --

    result1 = Subtract2.call(a: 3, b: 1)

    assert_predicate result1, :success?
    assert_equal 2, result1[:number]

    result2 = Subtract2.call(a: 3)

    assert_predicate result2, :success?
    assert_equal 1, result2[:number]
  end

  class Multiply1 < Micro::Case
    attribute :a, required: true
    attribute 'b', required: true

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply1
    err1 = assert_raises(ArgumentError) { Multiply1.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply1.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply1.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply2 < Micro::Case::Strict
    attribute :a
    attribute 'b'

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply2
    err1 = assert_raises(ArgumentError) { Multiply2.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply2.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply2.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply3 < Micro::Case::Strict
    attributes :a, 'b'

    def call!
      Success result: { number: a * b }
    end
  end

  def test_multiply3
    err1 = assert_raises(ArgumentError) { Multiply3.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply3.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply3.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply4 < Multiply2
  end

  def test_multiply4
    err1 = assert_raises(ArgumentError) { Multiply4.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply4.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply4.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  class Multiply5 < Multiply3
  end

  def test_multiply5
    err1 = assert_raises(ArgumentError) { Multiply5.call }
    assert_equal('missing keywords: :a, :b', err1.message )

    err2 = assert_raises(ArgumentError) { Multiply5.call(a: 1) }
    assert_equal('missing keyword: :b', err2.message )

    err3 = assert_raises(ArgumentError) { Multiply5.call(b: 1) }
    assert_equal('missing keyword: :a', err3.message )
  end

  # ---------- 3-level nesting via the block form ------------------------

  # `attribute :foo do ... end` builds an anonymous nested class wired
  # with init+accept. Chain three of them to get a customer→address→
  # city tree directly inside a use case. Coercion auto-builds each
  # level from the hash the caller passes; bubbling lifts deep
  # accept-errors all the way to the use case's `attributes_errors`,
  # which u-case turns into a Failure(:invalid_attributes).
  class CreateOrderBlock < Micro::Case
    attribute :order do
      attribute :customer do
        attribute :address do
          attribute :city, accept: String
          attribute :zip,  accept: String
        end
        attribute :name, accept: String
      end
      attribute :total, accept: Numeric
    end

    def call!
      Success result: { order: order }
    end
  end

  def test_block_form_three_level_nesting_coerces_each_level
    result = CreateOrderBlock.call(order: {
      customer: {
        address: { city: 'Lisbon', zip: '1000-001' },
        name:    'Rodrigo'
      },
      total: 99.9
    })

    assert_predicate(result, :success?)

    order = result[:order]
    assert_match(/CreateOrderBlock\(order\)\z/,                           order.class.to_s)
    assert_match(/CreateOrderBlock\(order\)\(customer\)\z/,               order.customer.class.to_s)
    assert_match(/CreateOrderBlock\(order\)\(customer\)\(address\)\z/,    order.customer.address.class.to_s)

    assert_equal('Lisbon',    order.customer.address.city)
    assert_equal('1000-001',  order.customer.address.zip)
    assert_equal('Rodrigo',   order.customer.name)
    assert_in_delta(99.9, order.total, 0.0001)
  end

  def test_block_form_three_level_nesting_bubbles_leaf_failure
    result = CreateOrderBlock.call(order: {
      customer: {
        address: { city: 12345, zip: '1000-001' },  # city is not a String
        name:    'Rodrigo'
      },
      total: 99.9
    })

    assert_predicate(result, :failure?)
    assert_equal(:invalid_attributes, result.type)

    # The use case's own `attributes_errors` only carries the top-level
    # marker — the detail lives at the leaf.
    assert_equal({ 'order' => 'is invalid' }, result[:errors])

    # Walk down through the use case to find the leaf-level detail.
    uc = result.use_case
    assert_equal({ 'customer' => 'is invalid' },         uc.order.attributes_errors)
    assert_equal({ 'address'  => 'is invalid' },         uc.order.customer.attributes_errors)
    assert_match(/kind of String/, uc.order.customer.address.attributes_errors['city'])
  end

  # ---------- 3-level nesting via three separate `accept:` classes ------

  # Same shape, expressed as three pre-built Micro::Attributes classes
  # composed via `accept:`. Hash → child coercion crosses every layer
  # automatically; the use case never has to build the tree by hand.
  class AddressEntity
    include Micro::Attributes.with(:initialize, :accept)
    attribute :city, accept: String
    attribute :zip,  accept: String
  end

  class CustomerEntity
    include Micro::Attributes.with(:initialize, :accept)
    attribute :address, accept: AddressEntity
    attribute :name,    accept: String
  end

  class OrderEntity
    include Micro::Attributes.with(:initialize, :accept)
    attribute :customer, accept: CustomerEntity
    attribute :total,    accept: Numeric
  end

  class CreateOrderAccept < Micro::Case
    attribute :order, accept: OrderEntity

    def call!
      Success result: { order: order }
    end
  end

  def test_accept_form_three_level_nesting_coerces_each_level
    result = CreateOrderAccept.call(order: {
      customer: { address: { city: 'Porto', zip: '4000-001' }, name: 'X' },
      total:    50
    })

    assert_predicate(result, :success?)

    order = result[:order]
    assert_kind_of(OrderEntity,    order)
    assert_kind_of(CustomerEntity, order.customer)
    assert_kind_of(AddressEntity,  order.customer.address)

    assert_equal('Porto',    order.customer.address.city)
    assert_equal('4000-001', order.customer.address.zip)
    assert_equal('X',        order.customer.name)
    assert_equal(50,         order.total)
  end

  def test_accept_form_three_level_nesting_bubbles_leaf_failure
    result = CreateOrderAccept.call(order: {
      customer: { address: { city: 999, zip: '4000-001' }, name: 'X' },  # bad city
      total:    50
    })

    assert_predicate(result, :failure?)
    assert_equal(:invalid_attributes, result.type)
    assert_equal({ 'order' => 'is invalid' }, result[:errors])

    uc = result.use_case
    assert_equal({ 'customer' => 'is invalid' }, uc.order.attributes_errors)
    assert_equal({ 'address'  => 'is invalid' }, uc.order.customer.attributes_errors)
    assert_match(/kind of String/, uc.order.customer.address.attributes_errors['city'])
  end

  def test_accept_form_three_level_nesting_bubbles_mid_failure
    # Bad value at the MIDDLE level (`customer.name` instead of leaf city).
    # The 'is invalid' marker propagates up from level 2; the leaf level
    # is untouched.
    result = CreateOrderAccept.call(order: {
      customer: { address: { city: 'Porto', zip: '4000-001' }, name: 42 },
      total:    50
    })

    assert_predicate(result, :failure?)
    assert_equal(:invalid_attributes, result.type)
    assert_equal({ 'order' => 'is invalid' }, result[:errors])

    uc = result.use_case
    assert_equal({ 'customer' => 'is invalid' }, uc.order.attributes_errors)
    assert_match(/kind of String/, uc.order.customer.attributes_errors['name'])
    refute_predicate(uc.order.customer.address, :attributes_errors?,
                     'leaf level is untouched when failure is at a mid level')
  end
end
