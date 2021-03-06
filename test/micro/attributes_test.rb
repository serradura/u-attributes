require 'digest'
require 'test_helper'

class Micro::AttributesTest < Minitest::Test
  class Biz
    include Micro::Attributes

    attribute :a
    attributes :b, :c

    def initialize(a, b, c='_c')
      @a, @b = a, b
      @c = c
    end
  end

  def test_custom_constructor
    object = Biz.new('a', nil)

    assert_equal('a', object.a)
    assert_equal('_c', object.c)
    assert_nil(object.b)
  end

  # ---

  class Bar
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute 'b'
  end

  def test_single_definitions
    bar1 = Bar.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    bar2 = Bar.new(a: false)

    assert_equal false, bar2.a
  end

  class Bar2
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute 'b', required: true
  end

  def test_bar2_attributes_assignment
    bar1 = Bar2.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    err = assert_raises(ArgumentError) { Bar2.new(a: false) }
    assert_equal('missing keyword: :b', err.message)
  end

  class Bar3
    include Micro::Attributes.with(:initialize)

    attribute :a, required: true
    attribute 'b', required: true
  end

  def test_bar3_attributes_assignment
    bar1 = Bar3.new(a: 'a', b: 'b')

    assert_equal 'a', bar1.a
    assert_equal 'b', bar1.b

    # ---

    err1 = assert_raises(ArgumentError) { Bar3.new(a: false) }
    assert_equal('missing keyword: :b', err1.message)

    err2 = assert_raises(ArgumentError) { Bar3.new({}) }
    assert_equal('missing keywords: :a, :b', err2.message)
  end

  # ---

  FalseValue = proc { false }

  class Baz
    include Micro::Attributes.with(:initialize)

    attribute :a
    attribute :b, default: FalseValue
    attribute 'c', default: -> { 'C' }
  end

  def test_single_definitions_with_default_values
    object = Baz.new(a: 'a')

    assert_equal 'a', object.a
    assert_equal false, object.b
    assert_equal 'C', object.c
  end

  # ---

  class Foo
    include Micro::Attributes.with(:initialize)

    attributes :a, 'b'
  end

  def test_multiple_definitions
    object = Foo.new(a: 'a', b: 'b')

    assert_equal 'a', object.a
    assert_equal 'b', object.b
  end

  # ---

  class Foz
    include Micro::Attributes.with(:initialize)

    attribute :a, default: -> value { value.to_s }
    attribute :b, default: proc { '_b' }
    attribute 'c', default: 'c_'
  end

  def test_multiple_definitions_with_default_values
    object = Foz.new(a: 'a')

    assert_equal 'a', object.a
    assert_equal '_b', object.b
    assert_equal 'c_', object.c
  end

  # ---

  def test_instance_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: :a)

    assert_equal({'a'=>'a', 'b'=>nil}, bar.attributes)
    assert_equal({'a'=>'a', 'b'=>nil}, foo.attributes)
    assert_equal({'b'=>false, 'c'=>'C', 'a'=>'a'}, baz.attributes)
    assert_equal({'b'=>'_b', 'c'=>'c_', 'a'=>'a'}, foz.attributes)

    assert(bar.attributes.frozen?)
    assert(foo.attributes.frozen?)
    assert(baz.attributes.frozen?)
    assert(foz.attributes.frozen?)
  end

  def test_the_slicing_of_the_instance_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert_equal({a: 'a'}, bar.attributes(:a))
    assert_equal({'a'=>'a', 'b'=>nil}, foo.attributes(['a', 'b']))
    assert_equal({'b'=>false, 'c'=>'C'}, baz.attributes('b', 'c'))
    assert_equal({b: '_b', c: 'c_', a: 'a'}, foz.attributes(:b, :c, :a))
  end

  class Person
    include Micro::Attributes.with(:initialize)

    attribute :first_name, default: 'John'
    attribute :last_name, default: 'Doe'

    def name
      "#{first_name} #{last_name}"
    end
  end

  def test_the_slicing_options
    person1 = Person.new({})
    person2 = Person.new(first_name: 'Rodrigo', last_name: 'Rodrigues')

    # --

    assert_equal({'first_name' => 'John'   , 'last_name' => 'Doe'      }, person1.attributes)
    assert_equal({'first_name' => 'Rodrigo', 'last_name' => 'Rodrigues'}, person2.attributes)

    # --

    assert_equal({'first_name' => 'John'   , 'last_name' => 'Doe'      }, person1.attributes(keys_as: String))
    assert_equal({'first_name' => 'Rodrigo', 'last_name' => 'Rodrigues'}, person2.attributes(keys_as: String))

    assert_equal({:first_name => 'John'   , :last_name => 'Doe'      }, person1.attributes(keys_as: Symbol))
    assert_equal({:first_name => 'Rodrigo', :last_name => 'Rodrigues'}, person2.attributes(keys_as: Symbol))


    assert_equal({'last_name'  => 'Doe'     }, person1.attributes([:last_name], keys_as: String))
    assert_equal({'first_name' => 'Rodrigo' }, person2.attributes(:first_name, keys_as: String))

    assert_equal({:last_name  => 'Doe'     }, person1.attributes('last_name', keys_as: Symbol))
    assert_equal({:first_name => 'Rodrigo' }, person2.attributes(['first_name'], keys_as: Symbol))

    # --

    assert_equal({'first_name' => 'John'   }, person1.attributes(without: :last_name))
    assert_equal({'first_name' => 'Rodrigo'}, person2.attributes(without: [:last_name]))

    assert_equal({}, person1.attributes(without: [:first_name, :last_name]))
    assert_equal({}, person2.attributes(without: [:first_name, :last_name]))

    # --

    assert_equal({'first_name' => 'John'   , 'last_name' => 'Doe'      , 'name'=> 'John Doe'          }, person1.attributes(with: :name))
    assert_equal({'first_name' => 'John'   , 'last_name' => 'Doe'      , 'name'=> 'John Doe'          }, person1.attributes(with: 'name'))
    assert_equal({'first_name' => 'Rodrigo', 'last_name' => 'Rodrigues', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(with: [:name]))
    assert_equal({'first_name' => 'Rodrigo', 'last_name' => 'Rodrigues', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(with: ['name']))

    # --

    assert_equal({:first_name  => 'John'   , 'name' => 'John Doe'         }, person1.attributes(:first_name, with: :name))
    assert_equal({'first_name' => 'John'   , 'name' => 'John Doe'         }, person1.attributes('first_name', with: 'name'))
    assert_equal({:first_name  => 'Rodrigo', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(:first_name, with: ['name']))
    assert_equal({'first_name' => 'Rodrigo', 'name' => 'Rodrigo Rodrigues'}, person2.attributes('first_name', with: [:name]))

    assert_equal({'first_name' => 'John'   , 'name' => 'John Doe'         }, person1.attributes(with: [:name], without: :last_name))
    assert_equal({'first_name' => 'John'   , 'name' => 'John Doe'         }, person1.attributes(with: ['name'], without: 'last_name'))
    assert_equal({'first_name' => 'Rodrigo', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(with: ['name'], without: 'last_name'))
    assert_equal({'first_name' => 'Rodrigo', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(with: [:name], without: :last_name))

    # --

    [Symbol, :symbol].each do |keys_as|
      assert_equal({:first_name => 'John'   , :name => 'John Doe'         }, person1.attributes(:first_name, with: :name, keys_as: keys_as))
      assert_equal({:first_name => 'John'   , :name => 'John Doe'         }, person1.attributes('first_name', with: 'name', keys_as: keys_as))
      assert_equal({:first_name => 'Rodrigo', :name => 'Rodrigo Rodrigues'}, person2.attributes(:first_name, with: ['name'], keys_as: keys_as))
      assert_equal({:first_name => 'Rodrigo', :name => 'Rodrigo Rodrigues'}, person2.attributes('first_name', with: [:name], keys_as: keys_as))

      assert_equal({:first_name => 'John'   , :name => 'John Doe'         }, person1.attributes(with: [:name], without: :last_name, keys_as: keys_as))
      assert_equal({:first_name => 'John'   , :name => 'John Doe'         }, person1.attributes(with: ['name'], without: 'last_name', keys_as: keys_as))
      assert_equal({:first_name => 'Rodrigo', :name => 'Rodrigo Rodrigues'}, person2.attributes(with: ['name'], without: 'last_name', keys_as: keys_as))
      assert_equal({:first_name => 'Rodrigo', :name => 'Rodrigo Rodrigues'}, person2.attributes(with: [:name], without: :last_name, keys_as: keys_as))
    end

    # --

    [String, :string].each do |keys_as|
      assert_equal({'first_name' => 'John'   , 'name' => 'John Doe'         }, person1.attributes(:first_name, with: :name, keys_as: keys_as))
      assert_equal({'first_name' => 'Rodrigo', 'name' => 'Rodrigo Rodrigues'}, person2.attributes(:first_name, with: ['name'], keys_as: keys_as))
    end
  end

  # ---

  def test_instance_defined_attributes
    bar = Bar.new(a: 'a')
    foo = Foo.new(a: 'a')
    baz = Baz.new(a: 'a')
    foz = Foz.new(a: :a)

    assert_equal(%w[a b], bar.defined_attributes)
    assert_equal(%w[a b], foo.defined_attributes)
    assert_equal(%w[a b c], baz.defined_attributes)
    assert_equal(%w[a b c], foz.defined_attributes)
  end

  # ---

  def test_attribute?
    #
    # Classes
    #
    assert Bar.attribute?(:a)
    assert Bar.attribute?('a')
    refute Bar.attribute?('c')
    refute Bar.attribute?(:c)

    assert Foz.attribute?(:a)
    assert Foz.attribute?('a')
    assert Foz.attribute?('c')
    refute Foz.attribute?(:d)
    refute Foz.attribute?('d')

    #
    # Instances
    #
    bar = Bar.new(a: 'a')
    foz = Foz.new(a: 'a')

    assert bar.attribute?(:a)
    assert bar.attribute?('a')
    refute bar.attribute?('c')
    refute bar.attribute?(:c)

    assert foz.attribute?(:a)
    assert foz.attribute?('a')
    assert foz.attribute?('c')
    refute foz.attribute?(:d)
    refute foz.attribute?('d')
  end

  # ---

  def test_instance_attribute
    [Biz.new('a', nil), Bar.new(a: 'a')].each do |instance|
      #
      # #attribute
      #
      assert_equal('a', instance.attribute(:a))
      assert_equal('a', instance.attribute('a'))

      assert_nil(instance.attribute(:b))
      assert_nil(instance.attribute('b'))

      assert_nil(instance.attribute(:unknown))
      assert_nil(instance.attribute('unknown'))

      #
      # #attribute!
      #
      assert_equal('a', instance.attribute!(:a))
      assert_equal('a', instance.attribute!('a'))

      assert_nil(instance.attribute!(:b))
      assert_nil(instance.attribute!('b'))

      err1 = assert_raises(NameError) { instance.attribute!(:unknown) }
      assert_equal('undefined attribute `unknown', err1.message)

      err2 = assert_raises(NameError) { instance.attribute!('unknown') }
      assert_equal('undefined attribute `unknown', err2.message)
    end
  end

  def test_instance_attribute_with_a_block
    [Biz.new('a', nil), Bar.new(a: 'a')].each do |instance|
      #
      # #attribute
      #
      acc1 = 0
      instance.attribute(:a) { |val| acc1 += 1 if val == 'a' }
      instance.attribute('a') { |val| acc1 += 1 if val == 'a' }
      assert_equal(2, acc1)

      instance.attribute(:b) { |val| acc1 += 1 if val.nil? }
      instance.attribute('b') { |val| acc1 += 1 if val.nil? }
      assert_equal(4, acc1)

      instance.attribute(:unknown) { |_val| acc1 += 1 }
      instance.attribute('unknown') { |_val| acc1 += 1 }
      assert_equal(4, acc1)

      #
      # #attribute!
      #
      acc2 = 0
      instance.attribute(:a) { |val| acc2 += 1 if val == 'a' }
      instance.attribute('a') { |val| acc2 += 1 if val == 'a' }
      assert_equal(2, acc2)

      instance.attribute(:b) { |val| acc2 += 1 if val.nil? }
      instance.attribute('b') { |val| acc2 += 1 if val.nil? }
      assert_equal(4, acc2)

      err1 = assert_raises(NameError) do
        instance.attribute!(:unknown) { |_val| acc2 += 1 }
      end
      assert_equal('undefined attribute `unknown', err1.message)

      err2 = assert_raises(NameError) do
        instance.attribute!('unknown') { |_val| acc2 += 1 }
      end
      assert_equal('undefined attribute `unknown', err2.message)
    end
  end

  # ---

  class Post
    attr_reader :title, :published

    def initialize(title:, published: false)
      @title, @published = title, published
    end

    def [](name)
      return if String(name) !~ /title|published/

      raise NotImplementedError
    end
  end

  class ExtractingAttributes
    include Micro::Attributes

    attributes :title, :body, :published
    attribute :category, default: :foods_and_drinks

    def initialize(post)
      self.attributes = extract_attributes_from(post)
    end
  end

  def test_extract_attributes_using_readers
    post = Post.new(title: 'Such post')
    object = ExtractingAttributes.new(post)

    assert_equal('Such post', object.title)
    assert_nil(object.body)
    assert_equal(false, object.published)
    assert_equal(:foods_and_drinks, object.category)
  end

  def test_extract_attributes_using_hash_access
    object = ExtractingAttributes.new({ title: "Melkor's demise", published: false })

    assert_equal("Melkor's demise", object.title)
    assert_nil(object.body)
    assert_equal(false, object.published)
    assert_equal(:foods_and_drinks, object.category)
  end

  # ---

  def test_the_attributes_access
    [Biz, Bar, Bar2, Bar3, Foo, Foz, ExtractingAttributes].each do |klass|
      assert_equal(:indifferent, klass.attributes_access)
    end
  end

  # ---

  begin
    class InvalidAttributesDefinition
      include Micro::Attributes

      attributes foo: :bar
    end
  rescue => err
    @@__invalid_attributes_definition = err
  end

  def test_invalid_attributes_definition
    assert_instance_of(Kind::Error, @@__invalid_attributes_definition)

    assert_equal('{:foo=>:bar} expected to be a kind of String/Symbol', @@__invalid_attributes_definition.message)
  end

  # ---

  begin
    class InvalidAttributesOptions
      include Micro::Attributes

      attributes :bar, foo: true
    end
  rescue => err
    @@__invalid_attributes_options = err
  end

  def test_invalid_attributes_options
    assert_instance_of(ArgumentError, @@__invalid_attributes_options)

    assert_equal(
      "Found one or more invalid options: :foo\n\nThe valid ones are: :default, :required, :freeze, :protected, :private, :validate, :validates, :accept, :reject, :allow_nil, :rejection_message",
      @@__invalid_attributes_options.message
    )
  end

  class FrozenAttributes
    include Micro::Attributes

    attributes :a
    attributes :b, freeze: true
    attributes :c, freeze: :after_dup
    attributes :d, freeze: :after_clone

    attributes :a1, :a2
    attributes :b1, :b2, freeze: true
    attributes :c1, :c2, freeze: :after_dup
    attributes :d1, :d2, freeze: :after_clone

    def initialize(data)
      self.attributes = data
    end
  end

  def test_the_attributes_freezing
    a, b, c, d = 'a', 'b', 'c', 'd'
    a1, a2 = 'a1', 'a2'
    b1, b2 = 'b1', 'b2'
    c1, c2 = 'c1', 'c2'
    d1, d2 = 'd1', 'd2'

    [c, d, c1, c2, d1, d2].each do |str|
      def str.foo; :foo; end
    end

    obj = FrozenAttributes.new(
      a: a, b: b, c: c, d: d,
      a1: a1, a2: a2,
      b1: b1, b2: b2,
      c1: c1, c2: c2,
      d1: d1, d2: d2
    )

    # --

    refute_predicate(a, :frozen?)
    refute_predicate(a1, :frozen?)
    refute_predicate(a2, :frozen?)

    assert_same(a, obj.a)
    assert_same(a1, obj.a1)
    assert_same(a2, obj.a2)

    # --

    assert_predicate(b, :frozen?)
    assert_predicate(b1, :frozen?)
    assert_predicate(b2, :frozen?)

    assert_same(b, obj.b)
    assert_same(b1, obj.b1)
    assert_same(b2, obj.b2)

    # --

    refute_predicate(c, :frozen?)
    refute_predicate(c1, :frozen?)
    refute_predicate(c2, :frozen?)

    refute_same(c, obj.c)
    refute_same(c1, obj.c1)
    refute_same(c2, obj.c2)

    assert_equal(c, obj.c)
    assert_equal(c1, obj.c1)
    assert_equal(c2, obj.c2)

    refute_respond_to(obj.c, :foo)
    refute_respond_to(obj.c1, :foo)
    refute_respond_to(obj.c2, :foo)

    # --

    refute_predicate(d, :frozen?)
    refute_predicate(d1, :frozen?)
    refute_predicate(d2, :frozen?)

    refute_same(d, obj.d)
    refute_same(d1, obj.d1)
    refute_same(d2, obj.d2)

    assert_equal(d, obj.d)
    assert_equal(d1, obj.d1)
    assert_equal(d2, obj.d2)

    assert_respond_to(obj.d, :foo)
    assert_respond_to(obj.d1, :foo)
    assert_respond_to(obj.d2, :foo)
  end

  class Password
    include Micro::Attributes

    attribute :value, default: -> value { String(value).strip }, protected: true

    def initialize(data)
      self.attributes = data
    end

    def ==(password)
      self.value == Kind.of(self.class, password).value
    end

    def digest
      @digest ||= Digest::SHA256.hexdigest(value)
    end
  end

  def test_protected_attributes
    pass = Password.new(value: '123456')
    pass_confirmation = Password.new(value: '123456')

    refute_respond_to(pass, :value)

    assert_equal(
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
      pass.digest
    )

    assert pass == pass_confirmation

    refute pass == Password.new(value: '123455')
  end

  class FullName
    include Micro::Attributes

    attributes :first, :last, default: -> value { String(value).strip }, private: true

    def initialize(data)
      self.attributes = data
    end

    def call
      "#{first} #{last}"
    end
  end

  def test_private_attributes
    full_name = FullName.new(first: ' Rodrigo   ', last: "\t\rSerradura\n")

    refute_respond_to(full_name, :first)
    refute_respond_to(full_name, :last)

    assert_equal('Rodrigo Serradura', full_name.call)
  end

  class AttributesVisibility
    include Micro::Attributes

    attribute :a
    attribute :b, private: true
    attribute :c, protected: true

    attributes :a1, :a2
    attributes :b1, :b2, private: true
    attributes :c1, :c2, protected: true

    def initialize(data)
      self.attributes = data
    end
  end

  def test_the_attributes_visibility
    a, a1, a2 = 'a', 'a1', 'a2'
    b, b1, b2 = 'b', 'b1', 'b2'
    c, c1, c2 = 'c', 'c1', 'c2'

    obj = AttributesVisibility.new(
      a: a, a1: a1, a2: a2,
      b: b, b1: b1, b2: b2,
      c: c, c1: c1, c2: c2
    )

    # --

    assert_equal(
      ['a', 'b', 'c', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2'],
      AttributesVisibility.attributes
    )

    assert_equal(
      ['a', 'b', 'c', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2'],
      obj.defined_attributes
    )

    # --

    assert_equal({
      public: ['a', 'a1', 'a2'],
      private: ['b', 'b1', 'b2'],
      protected: ['c', 'c1', 'c2']
    },
      AttributesVisibility.attributes_by_visibility
    )

    assert_equal({'a' => 'a', 'a1' => 'a1', 'a2' => 'a2'}, obj.attributes)

    assert_equal({
      public: ['a', 'a1', 'a2'],
      private: ['b', 'b1', 'b2'],
      protected: ['c', 'c1', 'c2']
    },
      obj.defined_attributes(:by_visibility)
    )

    # --

    [
      'foo', 'bar', :bar, :foo
    ].each { |key| refute obj.attribute?(key) }

    [
      'a', 'a1', 'a2', :a, :a1, :a2
    ].each { |key| assert obj.attribute?(key) }

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| refute obj.attribute?(key) }

    [
      'a', 'a1', 'a2', 'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :a, :a1, :a2, :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert obj.attribute?(key, true) }

    [
      'foo', 'bar', :bar, :foo
    ].each { |key| refute obj.attribute?(key, true) }

    # --

    [
      'a', 'a1', 'a2', :a, :a1, :a2
    ].each { |key| assert_equal(key.to_s, obj.attribute(key)) }

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each { |key| assert_nil(obj.attribute(key)) }

    # --

    [
      'b', 'b1', 'b2', 'c', 'c1', 'c2',
      :b, :b1, :b2, :c, :c1, :c2,
    ].each do |key|
      err = assert_raises(NameError) { obj.attribute!(key) }

      assert_equal("tried to access a private attribute `#{key}", err.message)
    end

    [
      'foo', 'bar', :bar, :foo
    ].each do |key|
      err = assert_raises(NameError) { obj.attribute!(key) }

      assert_equal("undefined attribute `#{key}", err.message)
    end

    # --

    [
      -> { obj.a }, -> { obj.a1 }, -> { obj.a2 }
    ].each { |fn| assert_match(/\Aa[12]?\z/, fn.call) }

    [
      -> { obj.b }, -> { obj.b1 }, -> { obj.b2 }
    ].each do |fn|
      assert_match(
        /private method `b[12]?' called for #<.+Test::AttributesVisibility/,
        assert_raises(NoMethodError, &fn).message
      )
    end

    [
      -> { obj.c }, -> { obj.c1 }, -> { obj.c2 }
    ].each do |fn|
      assert_match(
        /protected method `c[12]?' called for #<.+Test::AttributesVisibility/,
        assert_raises(NoMethodError, &fn).message
      )
    end
  end
end
