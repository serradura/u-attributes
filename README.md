<p align="center">
  <h1 align="center" id="-attributes"><img src="./assets/u-attributes_logo_v1.png" alt="μ-attributes" height="60"></h1>
  <p align="center"><i>Create "immutable" objects with no setters, just getters.</i></p>
  <p align="center">
    <a href="https://badge.fury.io/rb/u-attributes"><img src="https://badge.fury.io/rb/u-attributes.svg" alt="Gem Version" height="18"></a>
    <a href="https://github.com/serradura/u-attributes/actions/workflows/ci.yml"><img alt="Build Status" src="https://github.com/serradura/u-attributes/actions/workflows/ci.yml/badge.svg"></a>
    <br/>
    <a href="https://qlty.sh/gh/serradura/projects/u-attributes"><img src="https://qlty.sh/gh/serradura/projects/u-attributes/maintainability.svg" alt="Maintainability" /></a>
    <a href="https://qlty.sh/gh/serradura/projects/u-attributes"><img src="https://qlty.sh/gh/serradura/projects/u-attributes/coverage.svg" alt="Code Coverage" /></a>
    <br/>
    <img src="https://img.shields.io/badge/Ruby%20%3E%3D%202.7%2C%20%3C%3D%20Head-ruby.svg?colorA=444&colorB=333" alt="Ruby">
    <img src="https://img.shields.io/badge/Rails%20%3E%3D%206.0%2C%20%3C%3D%20Edge-rails.svg?colorA=444&colorB=333" alt="Rails">
  </p>
</p>

This gem allows you to define "immutable" objects, when using it your objects will only have getters and no setters.
So, if you change [[1](#with_attribute)] [[2](#with_attributes)] an attribute of the object, you’ll have a new object instance. That is, you transform the object instead of modifying it.

## Documentation <!-- omit in toc -->

| Version    | Documentation                                                 |
| ---------- | ------------------------------------------------------------- |
| unreleased | https://github.com/serradura/u-attributes/blob/main/README.md |
| 3.1.0      | https://github.com/serradura/u-attributes/blob/v3.x/README.md |
| 2.8.0      | https://github.com/serradura/u-attributes/blob/v2.x/README.md |

# Table of contents <!-- omit in toc -->

- [Installation](#installation)
- [Compatibility](#compatibility)
- [Features at a glance](#features-at-a-glance)
  - [What you get by default](#what-you-get-by-default)
  - [Opt-in extensions](#opt-in-extensions)
- [Usage](#usage)
  - [How to define attributes?](#how-to-define-attributes)
    - [`Micro::Attributes#attributes=`](#microattributesattributes)
      - [How to extract attributes from an object or hash?](#how-to-extract-attributes-from-an-object-or-hash)
      - [Is it possible to define an attribute as required?](#is-it-possible-to-define-an-attribute-as-required)
    - [`Micro::Attributes#attribute`](#microattributesattribute)
    - [`Micro::Attributes#attribute!`](#microattributesattribute-1)
    - [Attribute visibility (`private:`, `protected:`)](#attribute-visibility-private-protected)
    - [Freezing attribute values (`freeze:`)](#freezing-attribute-values-freeze)
  - [How to define multiple attributes?](#how-to-define-multiple-attributes)
  - [`Micro::Attributes.with(:initialize)`](#microattributeswithinitialize)
    - [`#with_attribute()`](#with_attribute)
    - [`#with_attributes()`](#with_attributes)
  - [Defining default values to the attributes](#defining-default-values-to-the-attributes)
  - [The strict initializer](#the-strict-initializer)
  - [Is it possible to inherit the attributes?](#is-it-possible-to-inherit-the-attributes)
    - [`.attribute!()`](#attribute)
  - [How to query the attributes?](#how-to-query-the-attributes)
    - [`.attributes`](#attributes)
    - [`.attribute?()`](#attribute-1)
    - [`#attribute?()`](#attribute-2)
    - [`#attributes()`](#attributes-1)
      - [`#attributes(keys_as:)`](#attributeskeys_as)
      - [`#attributes(*names)`](#attributesnames)
      - [`#attributes([names])`](#attributesnames-1)
      - [`#attributes(with:, without:)`](#attributeswith-without)
    - [`#defined_attributes`](#defined_attributes)
- [Built-in extensions](#built-in-extensions)
  - [Picking specific features](#picking-specific-features)
    - [`Micro::Attributes.with`](#microattributeswith)
    - [`Micro::Attributes.without`](#microattributeswithout)
  - [Picking all the features](#picking-all-the-features)
  - [Extensions](#extensions)
    - [Accept extension](#accept-extension)
      - [What can `accept:` / `reject:` receive?](#what-can-accept--reject-receive)
      - [`allow_nil:` option](#allow_nil-option)
      - [`rejection_message:` option](#rejection_message-option)
      - [Strict mode (`accept: :strict`)](#strict-mode-accept-strict)
      - [Interaction with other features](#interaction-with-other-features)
    - [`ActiveModel::Validation` extension](#activemodelvalidation-extension)
      - [`.attribute()` options](#attribute-options)
    - [Diff extension](#diff-extension)
    - [Initialize extension](#initialize-extension)
      - [Strict mode](#strict-mode)
    - [Keys as symbol extension](#keys-as-symbol-extension)
- [Composition](#composition)
  - [`Micro::Attributes.new`](#microattributesnew)
  - [Hash-style configuration for `Micro::Attributes.with`](#hash-style-configuration-for-microattributeswith)
  - [Nested attributes via `accept:`](#nested-attributes-via-accept)
  - [Defining nested attributes inline (block form)](#defining-nested-attributes-inline-block-form)
  - [Deep nesting & validation bubbling](#deep-nesting--validation-bubbling)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

# Installation

Add this line to your application's Gemfile and `bundle install`:

```ruby
gem 'u-attributes', '~> 3.0'
```

# Compatibility

| u-attributes | branch | ruby     | activemodel    |
| ------------ | ------ | -------- | -------------- |
| unreleased   | main   | >= 2.7   | >= 6.0         |
| 3.1.0        | v3.x   | >= 2.7   | >= 6.0         |
| 2.8.0        | v2.x   | >= 2.2.0 | >= 3.2, <= 8.1 |

This library is tested (CI matrix) against:

| Ruby / Rails | 6.0 | 6.1 | 7.0 | 7.1 | 7.2 | 8.0 | 8.1 | Edge |
| ------------ | --- | --- | --- | --- | --- | --- | --- | ---- |
| 2.7          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.0          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.1          |     |     | ✅  | ✅  | ✅  |     |     |      |
| 3.2          |     |     | ✅  | ✅  | ✅  | ✅  |     |      |
| 3.3          |     |     | ✅  | ✅  | ✅  | ✅  | ✅  | ✅   |
| 3.4          |     |     |     |     | ✅  | ✅  | ✅  | ✅   |
| 4.x          |     |     |     |     |     |     | ✅  | ✅   |
| Head         |     |     |     |     |     |     | ✅  | ✅   |

> **Note**: The activemodel is an optional dependency, this module [can be enabled](#activemodelvalidation-extension) to validate the attributes.

[⬆️ Back to Top](#table-of-contents-)

# Features at a glance

## What you get by default

Everything in this table is available the moment you `include Micro::Attributes` — no `.with(...)` required.

| Capability | Example | Notes |
| ---------- | ------- | ----- |
| Define an attribute | `attribute :name` | Public reader; no setter |
| Define many at once | `attributes :a, :b, default: 0` | Trailing options apply to every name |
| Override in a subclass | `attribute! :name, default: 'X'` | Subclass-only |
| Default value | `attribute :name, default: 'X'` | Static value or `proc { ... }` / `->(v) { ... }` |
| Required (without strict) | `attribute :name, required: true` | Raises on missing key if `attributes=` is invoked with one |
| Freeze the value | `attribute :name, freeze: true` | Also `:after_dup`, `:after_clone` |
| Visibility | `attribute :secret, private: true` | Or `protected: true`; hidden from `#attributes` hash |
| Layer extensions inline | `with :keys_as_symbol` | Class macro — see [Extensions](#opt-in-extensions) |
| Block-form nested | `attribute :foo do ... end` | Anonymous inline class; inherits the host's feature mix |
| Hash → child coercion | `attribute :child, accept: Other` | When `Other` includes `Micro::Attributes`, a hash auto-builds an instance |
| Deep-error bubble marker | `parent.attributes_errors['child']` | Descendant errors mirror up as `'is invalid'` (requires `accept` to be enabled for the parent so the error hash exists) |
| Struct-style factory | `User = Micro::Attributes.new { attribute :name }` | Returns a class; preset is `initialize: true, accept: true` |

## Opt-in extensions

Mix any combination via `Micro::Attributes.with(...)` — hash-style and positional-symbol APIs both work and can be combined.

| Extension                   | Hash API                       | Positional API                | What it adds                                                                                                                                                       |
| --------------------------- | ------------------------------ | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Initialize**              | `initialize: true`             | `:initialize`                 | Auto-generated `new(hash)` constructor + immutable `#with_attribute(s)`                                                                                            |
| **Initialize (strict)**     | `initialize: :strict`          | (hash only)                   | All attributes without a default become **required**; missing keys raise `ArgumentError`. Implies `Initialize`.                                                    |
| **Accept**                  | `accept: true`                 | `:accept`                     | `accept:` / `reject:` / `allow_nil:` / `rejection_message:` validation; `#attributes_errors`, `#attributes_errors?`, `#accepted_attributes`, `#rejected_attributes` |
| **Accept (strict)**         | `accept: :strict`              | (hash only)                   | Any rejection raises `ArgumentError` immediately. Implies `Accept`.                                                                                                |
| **Diff**                    | `diff: true`                   | `:diff`                       | `#diff_attributes(other)` returns a `Diff::Changes` (`#changed?`, `#differences`, etc.)                                                                            |
| **Keys as Symbol**          | `keys_as: :symbol`             | `:keys_as_symbol`             | Symbol-keyed storage; disables indifferent access for performance/strictness                                                                                       |
| **ActiveModel Validations** | `active_model: :validations`   | `:activemodel_validations`    | Mixes `ActiveModel::Validations` (`valid?`, `errors`, `validates :x, presence: true`, the `validates:` / `validate:` attribute options); auto-registers a `__validate_nested_entities__` validator that bubbles **deep** descendant invalidity into `errors`. Requires the `activemodel` gem. |

### Picking a combination

Two equivalent ways to enable Initialize + Accept + Diff + symbol keys:

```ruby
# Hash style — self-documenting; great when you're enabling several
include Micro::Attributes.with(
  initialize: true,
  accept:     true,
  diff:       true,
  keys_as:    :symbol
)

# Positional style — terser when you're just turning things on
include Micro::Attributes.with(:initialize, :accept, :diff, :keys_as_symbol)
```

For strict variants, the hash form is unavoidable: `Micro::Attributes.with(initialize: :strict, accept: :strict)`.

[⬆️ Back to Top](#table-of-contents-)

# Usage

## How to define attributes?

By default, you must define the class constructor.

```ruby
class Person
  include Micro::Attributes

  attribute :age
  attribute :name

  def initialize(name: 'John Doe', age:)
    @name, @age = name, age
  end
end

person = Person.new(age: 21)

person.age  # 21
person.name # John Doe

# By design the attributes are always exposed as reader methods (getters).
# If you try to call a setter you will see a NoMethodError.
#
# person.name = 'Rodrigo'
# NoMethodError (undefined method `name=' for #<Person:0x0000... @name='John Doe', @age=21>)
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Attributes#attributes=`

This is a protected method to make easier the assignment in a constructor. e.g.

```ruby
class Person
  include Micro::Attributes

  attribute :age
  attribute :name, default: 'John Doe'

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new(age: 20)

person.age  # 20
person.name # John Doe
```

#### How to extract attributes from an object or hash?

You can extract attributes using the `extract_attributes_from` method. For each attribute name it
will first call the reader method (`object.attribute_key`) when available, and fall back to the
hash accessor (`object[attribute_key]`) otherwise. The reader method has priority because it lets
the source object encapsulate any computed/derived value.

```ruby
class Person
  include Micro::Attributes

  attribute :age
  attribute :name, default: 'John Doe'

  def initialize(user:)
    self.attributes = extract_attributes_from(user)
  end
end

# extracting from an object

class User
  attr_accessor :age, :name
end

user = User.new
user.age = 20

person = Person.new(user: user)

person.age  # 20
person.name # John Doe

# extracting from a hash

another_person = Person.new(user: { age: 55, name: 'Julia Not Roberts' })

another_person.age  # 55
another_person.name # Julia Not Roberts
```

#### Is it possible to define an attribute as required?

You only need to use the `required: true` option.

But to this work, you need to assign the attributes using the [`#attributes=`](#microattributesattributes) method or the extensions: [initialize](#initialize-extension), [activemodel_validations](#activemodelvalidation-extension).

```ruby
class Person
  include Micro::Attributes

  attribute :age
  attribute :name, required: true

  def initialize(attributes)
    self.attributes = attributes
  end
end

Person.new(age: 32) # ArgumentError (missing keyword: :name)
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Attributes#attribute`

Use this method with a valid attribute name to get its value.

```ruby
person = Person.new(age: 20)

person.attribute('age') # 20
person.attribute(:name) # John Doe
person.attribute('foo') # nil
```

If you pass a block, it will be executed only if the attribute was valid.

```ruby
person.attribute(:name) { |value| puts value } # John Doe
person.attribute('age') { |value| puts value } # 20
person.attribute('foo') { |value| puts value } # !! Nothing happened, because of the attribute doesn't exist.
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Attributes#attribute!`

Works like the `#attribute` method, but it will raise an exception when the attribute doesn't exist.

```ruby
person.attribute!('foo')                   # NameError (undefined attribute `foo)

person.attribute!('foo') { |value| value } # NameError (undefined attribute `foo)
```

[⬆️ Back to Top](#table-of-contents-)

### Attribute visibility (`private:`, `protected:`)

By default every attribute reader is `public`. Use the `private: true` or `protected: true`
options to restrict the reader's visibility — useful for things like passwords, tokens, and any
internal value you don't want to expose on the public API.

Private/protected attributes are also excluded from the public attribute set (`#attributes`,
`.attributes`, `#attribute?`), so they don't leak through serialization or enumeration. To check
or fetch them explicitly, pass `true` as the second argument to `#attribute?` (or use
`#attribute!`).

```ruby
require 'digest'

class User::SignUpParams
  include Micro::Attributes.with(:initialize)

  TrimString = ->(value) { String(value).strip }

  attribute  :email,                                              default: TrimString
  attributes :password, :password_confirmation, default: TrimString, private: true

  def password_digest
    return unless password == password_confirmation

    Digest::SHA256.hexdigest(password)
  end
end

User::SignUpParams.attributes               # ["email", "password", "password_confirmation"]
User::SignUpParams.attributes_by_visibility # { public: ["email"], private: ["password", "password_confirmation"], protected: [] }

user = User::SignUpParams.new(
  email: 'email@example.com',
  password: 'secret',
  password_confirmation: 'secret'
)

user.attributes                  # { "email" => "email@example.com" }

user.attribute?('email')         # true
user.attribute?('password')      # false  (not in the public set)
user.attribute?('password', true) # true   (use the second arg to look at all attributes)

user.attribute('password')       # nil     (returns nil instead of leaking the value)
user.attribute!('password')      # NameError ("tried to access a private attribute `password")

user.password                    # NoMethodError (private method `password' called for ...)
```

- `private:` and `protected:` map directly to Ruby's method-visibility semantics on the reader.
- The visibility configuration is preserved on inheritance.
- Works with the `:keys_as_symbol` extension (`attributes_by_visibility` will return the keys in
  the configured type).

The class-level `attributes_by_visibility` method returns a hash with `:public`, `:private`, and
`:protected` keys so you can introspect how each attribute was declared.

[⬆️ Back to Top](#table-of-contents-)

### Freezing attribute values (`freeze:`)

Use the `freeze:` option to make sure the value stored in the attribute can't be mutated after
the object is built. Three modes are supported:

| Value          | Behavior                                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `true`         | Calls `value.freeze` on the incoming value. The original is frozen.                                                      |
| `:after_dup`   | `value.dup.freeze` — freezes a shallow copy; the original stays free.                                                    |
| `:after_clone` | `value.clone.freeze` — same as above but uses `#clone` (preserves singleton methods, frozen state, tainted state, etc.). |

```ruby
class Person
  include Micro::Attributes.with(:initialize)

  attribute :name,    freeze: true
  attribute :address, freeze: :after_dup
  attribute :payload, freeze: :after_clone
end

raw_name = +"Rodrigo"

person = Person.new(
  name:    raw_name,
  address: 'Av. Paulista',
  payload: { id: 1 }
)

person.name.frozen?    # true
raw_name.frozen?       # true  -> freeze: true mutates the original

person.address.frozen? # true
'Av. Paulista'.frozen? # depends on the source string; the duplicate is what's frozen
```

`freeze:` is applied after the default value resolution, so the frozen value reflects whatever
the attribute ends up holding (raw value, default, or callable-default result).

[⬆️ Back to Top](#table-of-contents-)

## How to define multiple attributes?

Use `.attributes` with a list of attribute names.

```ruby
class Person
  include Micro::Attributes

  attributes :age, :name

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new(age: 32)

person.name # nil
person.age  # 32
```

You can also pass a trailing options hash and every attribute in the list will be declared with
those options. This is the canonical way to declare several attributes that share the same
configuration (default value, visibility, freezing, validations, etc.).

```ruby
class User::SignUpParams
  include Micro::Attributes.with(:initialize, :accept)

  TrimString = ->(value) { String(value).strip }

  attribute  :email,                                              default: TrimString
  attributes :password, :password_confirmation, reject: :empty?,  default: TrimString, private: true
end
```

> **Note:** Unlike `.attribute`, this method accepts a shared options hash but defines all listed
> attributes with the same configuration. If you need different defaults/options per attribute,
> use `#attribute()` once per attribute.

[⬆️ Back to Top](#table-of-contents-)

## `Micro::Attributes.with(:initialize)`

Use `Micro::Attributes.with(:initialize)` to define a constructor to assign the attributes. e.g.

```ruby
class Person
  include Micro::Attributes.with(:initialize)

  attribute :age, required: true
  attribute :name, default: 'John Doe'
end

person = Person.new(age: 18)

person.age  # 18
person.name # John Doe
```

This extension enables two methods for your objects.
The `#with_attribute()` and `#with_attributes()`.

### `#with_attribute()`

```ruby
another_person = person.with_attribute(:age, 21)

another_person.age            # 21
another_person.name           # John Doe
another_person.equal?(person) # false
```

### `#with_attributes()`

Use it to assign multiple attributes

```ruby
other_person = person.with_attributes(name: 'Serradura', age: 32)

other_person.age            # 32
other_person.name           # Serradura
other_person.equal?(person) # false
```

If you pass a value different of a Hash, a Kind::Error will be raised.

```ruby
Person.new(1) # Kind::Error (1 expected to be a kind of Hash)
```

[⬆️ Back to Top](#table-of-contents-)

## Defining default values to the attributes

To do this, you only need make use of the `default:` keyword. e.g.

```ruby
class Person
  include Micro::Attributes.with(:initialize)

  attribute :age
  attribute :name, default: 'John Doe'
end
```

There are two different strategies to define default values.

1. Pass a regular object, like in the previous example.
2. Pass a `proc`/`lambda`, and if it has an argument you will receive the attribute value to do something before assign it.

```ruby
class Person
  include Micro::Attributes.with(:initialize)

  attribute :age, default: -> age { age&.to_i }
  attribute :name, default: -> name { String(name || 'John Doe').strip }
end
```

[⬆️ Back to Top](#table-of-contents-)

## The strict initializer

Use `.with(initialize: :strict)` to forbids an instantiation without all the attribute keywords.

In other words, it is equivalent to you define all the attributes using the [`required: true` option](#is-it-possible-to-define-an-attribute-as-required).

```ruby
class StrictPerson
  include Micro::Attributes.with(initialize: :strict)

  attribute :age
  attribute :name, default: 'John Doe'
end

StrictPerson.new({}) # ArgumentError (missing keyword: :age)
```

An attribute with a default value can be omitted.

```ruby
person_without_age = StrictPerson.new(age: nil)

person_without_age.age  # nil
person_without_age.name # 'John Doe'
```

> **Note:** Except for this validation the `.with(initialize: :strict)` method will works in the same ways of `.with(:initialize)`.

[⬆️ Back to Top](#table-of-contents-)

## Is it possible to inherit the attributes?

Yes. e.g.

```ruby
class Person
  include Micro::Attributes.with(:initialize)

  attribute :age
  attribute :name, default: 'John Doe'
end

class Subclass < Person # Will preserve the parent class attributes
  attribute :foo
end

instance = Subclass.new({})

instance.name              # John Doe
instance.respond_to?(:age) # true
instance.respond_to?(:foo) # true
```

[⬆️ Back to Top](#table-of-contents-)

### `.attribute!()`

This method allows us to redefine the attributes default data that was defined in the parent class. e.g.

```ruby
class AnotherSubclass < Person
  attribute! :name, default: 'Alfa'
end

alfa_person = AnotherSubclass.new({})

alfa_person.name # 'Alfa'
alfa_person.age  # nil

class SubSubclass < Subclass
  attribute! :age, default: 0
  attribute! :name, default: 'Beta'
end

beta_person = SubSubclass.new({})

beta_person.name # 'Beta'
beta_person.age  # 0
```

[⬆️ Back to Top](#table-of-contents-)

## How to query the attributes?

All of the methods that will be explained can be used with any of the built-in extensions.

**PS:** We will use the class below for all of the next examples.

```ruby
class Person
  include Micro::Attributes

  attribute :age
  attribute :first_name, default: 'John'
  attribute :last_name, default: 'Doe'

  def initialize(options)
    self.attributes = options
  end

  def name
    "#{first_name} #{last_name}"
  end
end
```

### `.attributes`

Listing all the class attributes.

```ruby
Person.attributes # ["age", "first_name", "last_name"]
```

### `.attribute?()`

Checking the existence of some attribute.

```ruby
Person.attribute?(:first_name)  # true
Person.attribute?('first_name') # true

Person.attribute?('foo') # false
Person.attribute?(:foo)  # false
```

### `#attribute?()`

Checking the existence of some attribute in an instance.

```ruby
person = Person.new(age: 20)

person.attribute?(:name)  # true
person.attribute?('name') # true

person.attribute?('foo') # false
person.attribute?(:foo)  # false
```

### `#attributes()`

Fetching all the attributes with their values.

```ruby
person1 = Person.new(age: 20)
person1.attributes # {"age"=>20, "first_name"=>"John", "last_name"=>"Doe"}

person2 = Person.new(first_name: 'Rodrigo', last_name: 'Rodrigues')
person2.attributes # {"age"=>nil, "first_name"=>"Rodrigo", "last_name"=>"Rodrigues"}
```

#### `#attributes(keys_as:)`

Use the `keys_as:` option with `Symbol`/`:symbol` or `String`/`:string` to transform the attributes hash keys.

```ruby
person1 = Person.new(age: 20)
person2 = Person.new(first_name: 'Rodrigo', last_name: 'Rodrigues')

person1.attributes(keys_as: Symbol) # {:age=>20, :first_name=>"John", :last_name=>"Doe"}
person2.attributes(keys_as: String) # {"age"=>nil, "first_name"=>"Rodrigo", "last_name"=>"Rodrigues"}

person1.attributes(keys_as: :symbol) # {:age=>20, :first_name=>"John", :last_name=>"Doe"}
person2.attributes(keys_as: :string) # {"age"=>nil, "first_name"=>"Rodrigo", "last_name"=>"Rodrigues"}
```

#### `#attributes(*names)`

Slices the attributes to include only the given keys (in their types).

```ruby
person = Person.new(age: 20)

person.attributes(:age)               # {:age => 20}
person.attributes(:age, :first_name)  # {:age => 20, :first_name => "John"}
person.attributes('age', 'last_name') # {"age" => 20, "last_name" => "Doe"}

person.attributes(:age, 'last_name') # {:age => 20, "last_name" => "Doe"}

# You could also use the keys_as: option to ensure the same type for all of the hash keys.

person.attributes(:age, 'last_name', keys_as: Symbol) # {:age=>20, :last_name=>"Doe"}
```

#### `#attributes([names])`

As the previous example, this methods accepts a list of keys to slice the attributes.

```ruby
person = Person.new(age: 20)

person.attributes([:age])               # {:age => 20}
person.attributes([:age, :first_name])  # {:age => 20, :first_name => "John"}
person.attributes(['age', 'last_name']) # {"age" => 20, "last_name" => "Doe"}

person.attributes([:age, 'last_name']) # {:age => 20, "last_name" => "Doe"}

# You could also use the keys_as: option to ensure the same type for all of the hash keys.

person.attributes([:age, 'last_name'], keys_as: Symbol) # {:age=>20, :last_name=>"Doe"}
```

#### `#attributes(with:, without:)`

Use the `with:` option to include any method value of the instance inside of the hash, and,
you can use the `without:` option to exclude one or more attribute keys from the final hash.

```ruby
person = Person.new(age: 20)

person.attributes(without: :age)               # {"first_name"=>"John", "last_name"=>"Doe"}
person.attributes(without: [:age, :last_name]) # {"first_name"=>"John"}

person.attributes(with: [:name], without: [:first_name, :last_name]) # {"age"=>20, "name"=>"John Doe"}

# To achieves the same output of the previous example, use the attribute names to slice only them.

person.attributes(:age, with: [:name]) # {:age=>20, "name"=>"John Doe"}

# You could also use the keys_as: option to ensure the same type for all of the hash keys.

person.attributes(:age, with: [:name], keys_as: Symbol) # {:age=>20, :name=>"John Doe"}
```

### `#defined_attributes`

Listing all the available attributes.

```ruby
person = Person.new(age: 20)

person.defined_attributes # ["age", "first_name", "last_name"]
```

[⬆️ Back to Top](#table-of-contents-)

# Built-in extensions

You can use the method `Micro::Attributes.with()` to combine and require only the features that better fit your needs.

But, if you desire except one or more features, use the `Micro::Attributes.without()` method.

## Picking specific features

### `Micro::Attributes.with`

```ruby
Micro::Attributes.with(:initialize)

Micro::Attributes.with(:initialize, :keys_as_symbol)

Micro::Attributes.with(:keys_as_symbol, initialize: :strict)

Micro::Attributes.with(:diff, :initialize)

Micro::Attributes.with(:diff, initialize: :strict)

Micro::Attributes.with(:diff, :keys_as_symbol, initialize: :strict)

Micro::Attributes.with(:activemodel_validations)

Micro::Attributes.with(:activemodel_validations, :diff)

Micro::Attributes.with(:activemodel_validations, :diff, initialize: :strict)

Micro::Attributes.with(:activemodel_validations, :diff, :keys_as_symbol, initialize: :strict)
```

The method `Micro::Attributes.with()` will raise an exception if no arguments/features were declared.

```ruby
class Job
  include Micro::Attributes.with() # ArgumentError (Invalid feature name! Available options: :accept, :activemodel_validations, :diff, :initialize, :keys_as_symbol)
end
```

### `Micro::Attributes.without`

Picking _except_ one or more features

```ruby
Micro::Attributes.without(:diff) # will load :activemodel_validations, :keys_as_symbol and initialize: :strict

Micro::Attributes.without(initialize: :strict) # will load :activemodel_validations, :diff and :keys_as_symbol
```

You can also pair `:accept` with any other feature, and switch into strict mode by passing the
hash form `accept: :strict`:

```ruby
Micro::Attributes.with(:accept)

Micro::Attributes.with(:accept, :diff, :initialize)

Micro::Attributes.with(:accept, :activemodel_validations, :diff, :keys_as_symbol)

Micro::Attributes.with(:diff, :keys_as_symbol, initialize: :strict, accept: :strict)
```

## Picking all the features

```ruby
Micro::Attributes.with_all_features

# This method returns the same of:

Micro::Attributes.with(:accept, :activemodel_validations, :diff, :keys_as_symbol, initialize: :strict)
```

[⬆️ Back to Top](#table-of-contents-)

## Extensions

### Accept extension

The `:accept` extension adds a lightweight, dependency-free validation mechanism. Use the
`accept:` / `reject:` options on an attribute to validate the assigned value, and inspect the
result through `#attributes_errors`, `#accepted_attributes`, and `#rejected_attributes`.

```ruby
class User
  include Micro::Attributes.with(:initialize, :accept)

  attribute :age,   accept: Integer, allow_nil: true
  attribute :name,  accept: -> v { v.is_a?(String) && !v.empty? }, default: 'John Doe'
  attribute :email, accept: :present?
end

user = User.new({})

user.attributes_errors?   # false
user.accepted_attributes? # true
user.rejected_attributes? # false

User.new(age: 'twenty', email: nil).tap do |bad|
  bad.attributes_errors?   # true
  bad.attributes_errors    # { "age" => "expected to be a kind of Integer", "email" => "expected to be present?" }
  bad.accepted_attributes  # ["name"]
  bad.rejected_attributes  # ["age", "email"]
end
```

#### What can `accept:` / `reject:` receive?

| Type                                                           | `accept:` means                                 | `reject:` means                                |
| -------------------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| `Class`/`Module`                                               | `value.kind_of?(expected)` must be true         | `value.kind_of?(expected)` must be false       |
| Predicate `:sym?` (ends with `?`)                              | `value.public_send(:sym?)` must be true         | `value.public_send(:sym?)` must be false       |
| Anything callable (proc, lambda, object responding to `#call`) | result of `expected.call(value)` must be truthy | result of `expected.call(value)` must be falsy |

Default rejection messages follow the pattern below; you can override them with
`rejection_message:` (see further down).

```ruby
attribute :name, accept: :present?   # "expected to be present?"
attribute :name, reject: :empty?     # "expected to not be empty?"
attribute :name, accept: String      # "expected to be a kind of String"
attribute :name, reject: String      # "expected to not be a kind of String"
attribute :name, accept: ->(v) { v }  # "is invalid"
```

#### `allow_nil:` option

Skip validation when the incoming value is `nil`.

```ruby
class User
  include Micro::Attributes.with(:initialize, :accept)

  attribute :age, accept: Integer, allow_nil: true
end

User.new(age: nil).attributes_errors? # false
User.new(age: 21).attributes_errors?  # false
User.new(age: 'x').attributes_errors? # true
```

#### `rejection_message:` option

Customize the error message either with a String or with a callable. A callable receives the
attribute name as its first argument, so the same builder can be reused across attributes (handy
for i18n).

```ruby
class User
  include Micro::Attributes.with(:initialize, :accept)

  attribute :name, accept: String,  rejection_message: 'must be a string'
  attribute :age,  accept: Integer, rejection_message: ->(key) { "#{key} must be an integer" }
end

User.new(name: 1, age: 'x').attributes_errors
# => { "name" => "must be a string", "age" => "age must be an integer" }
```

Callable validators can also expose a `#rejection_message` method themselves, and it will be used
as the default message for that validator:

```ruby
class FilledString
  def call(value)
    value.is_a?(String) && !value.empty?
  end

  def rejection_message
    ->(key) { "#{key} can't be an empty string" }
  end
end

class User
  include Micro::Attributes.with(:initialize, :accept)

  attribute :name, accept: FilledString.new
end
```

#### Strict mode (`accept: :strict`)

Use `Micro::Attributes.with(accept: :strict)` to raise as soon as any attribute is rejected,
instead of collecting errors silently.

```ruby
class User
  include Micro::Attributes.with(initialize: :strict, accept: :strict)

  attribute :age,  accept: Integer
  attribute :name, accept: ->(v) { v.is_a?(String) && !v.empty? }, default: 'John doe'
end

User.new(age: 'x', name: nil)
# ArgumentError:
# One or more attributes were rejected. Errors:
# * :age expected to be a kind of Integer
# * :name is invalid
```

#### Interaction with other features

- Validation runs **after** the default value resolution, so defaults are validated like any
  regular value.
- When combined with the [ActiveModel::Validation extension](#activemodelvalidation-extension),
  the `:accept` checks run first; AM validations only run if every attribute is accepted.
- `accept:` plays nicely with [`freeze:`](#freezing-attribute-values-freeze) and
  [`private:`/`protected:`](#attribute-visibility-private-protected). See the combined example
  below.

```ruby
require 'digest'

class User::SignUpParams
  include Micro::Attributes.with(:initialize, accept: :strict)

  TrimString = ->(value) { String(value).strip }

  attribute  :email,                                              default: TrimString,
             accept: ->(s) { s =~ /\A.+@.+\..+\z/ }, freeze: :after_dup
  attributes :password, :password_confirmation, default: TrimString,
             reject: :empty?, private: true

  def password_digest
    Digest::SHA256.hexdigest(password) if password == password_confirmation
  end
end
```

[⬆️ Back to Top](#table-of-contents-)

### `ActiveModel::Validation` extension

If your application uses ActiveModel as a dependency (like a regular Rails app). You will be enabled to use the `activemodel_validations` extension.

```ruby
class Job
  include Micro::Attributes.with(:activemodel_validations)

  attribute :id
  attribute :state, default: 'sleeping'

  validates! :id, :state, presence: true
end

Job.new({}) # ActiveModel::StrictValidationFailed (Id can't be blank)

job = Job.new(id: 1)

job.id    # 1
job.state # 'sleeping'
```

#### `.attribute()` options

You can use the `validate` or `validates` options to define your attributes. e.g.

```ruby
class Job
  include Micro::Attributes.with(:activemodel_validations)

  attribute :id, validates: { presence: true }
  attribute :state, validate: :must_be_a_filled_string

  def must_be_a_filled_string
    return if state.is_a?(String) && state.present?

    errors.add(:state, 'must be a filled string')
  end
end
```

[⬆️ Back to Top](#table-of-contents-)

### Diff extension

Provides a way to track changes in your object attributes.

```ruby
require 'securerandom'

class Job
  include Micro::Attributes.with(:initialize, :diff)

  attribute :id
  attribute :state, default: 'sleeping'
end

job = Job.new(id: SecureRandom.uuid())

job.id    # A random UUID generated from SecureRandom.uuid(). e.g: 'e68bcc74-b91c-45c2-a904-12f1298cc60e'
job.state # 'sleeping'

job_running = job.with_attribute(:state, 'running')

job_running.state # 'running'

job_changes = job.diff_attributes(job_running)

#-----------------------------#
# #present?, #blank?, #empty? #
#-----------------------------#

job_changes.present? # true
job_changes.blank?   # false
job_changes.empty?   # false

#-----------#
# #changed? #
#-----------#
job_changes.changed? # true

job_changes.changed?(:id)    # false

job_changes.changed?(:state) # true
job_changes.changed?(:state, from: 'sleeping', to: 'running') # true

#----------------#
# #differences() #
#----------------#
job_changes.differences # {'state'=> {'from' => 'sleeping', 'to' => 'running'}}
```

[⬆️ Back to Top](#table-of-contents-)

### Initialize extension

1. Creates a constructor to assign the attributes.
2. Add methods to build new instances when some data was assigned.

```ruby
class Job
  include Micro::Attributes.with(:initialize)

  attributes :id, :state
end

job_null = Job.new({})

job.id    # nil
job.state # nil

job = Job.new(id: 1, state: 'sleeping')

job.id    # 1
job.state # 'sleeping'

##############################################
# Assigning new values to get a new instance #
##############################################

#-------------------#
# #with_attribute() #
#-------------------#

new_job = job.with_attribute(:state, 'running')

new_job.id          # 1
new_job.state       # running
new_job.equal?(job) # false

#--------------------#
# #with_attributes() #
#--------------------#
#
# Use it to assign multiple attributes

other_job = job.with_attributes(id: 2, state: 'killed')

other_job.id          # 2
other_job.state       # killed
other_job.equal?(job) # false
```

[⬆️ Back to Top](#table-of-contents-)

#### Strict mode

1. Creates a constructor to assign the attributes.
2. Adds methods to build new instances when some data was assigned.
3. **Forbids missing keywords**.

```ruby
class Job
  include Micro::Attributes.with(initialize: :strict)

  attributes :id, :state
end
#-----------------------------------------------------------------------#
# The strict initialize mode will require all the keys when initialize. #
#-----------------------------------------------------------------------#

Job.new({})

# The code above will raise:
# ArgumentError (missing keywords: :id, :state)

#---------------------------#
# Samples passing some data #
#---------------------------#

job_null = Job.new(id: nil, state: nil)

job.id    # nil
job.state # nil

job = Job.new(id: 1, state: 'sleeping')

job.id    # 1
job.state # 'sleeping'
```

> **Note**: This extension works like the `initialize` extension. So, look at its section to understand all of the other features.

[⬆️ Back to Top](#table-of-contents-)

### Keys as symbol extension

Disables the indifferent access requiring the declaration/usage of the attributes as symbols.

The advantage of this extension over the default behavior is because it avoids an unnecessary allocation in memory of strings. All the keys are transformed into strings in the indifferent access mode, but, with this extension, this typecasting will be avoided. So, it has a better performance and reduces the usage of memory/Garbage collector, but gives for you the responsibility to always use symbols to set/access the attributes.

```ruby
class Job
  include Micro::Attributes.with(:initialize, :keys_as_symbol)

  attribute :id
  attribute :state, default: 'sleeping'
end

job = Job.new(id: 1)

job.attributes # {:id => 1, :state => "sleeping"}

job.attribute?(:id) # true
job.attribute?('id') # false

job.attribute(:id) # 1
job.attribute('id') # nil

job.attribute!(:id) # 1
job.attribute!('id') # NameError (undefined attribute `id)
```

As you could see in the previous example only symbols will work to do something with the attributes.

This extension also changes the `diff extension` making everything (arguments, outputs) working only with symbols.

[⬆️ Back to Top](#table-of-contents-)

# Composition

Every `Micro::Attributes` class — whether you reach for `include Micro::Attributes.with(...)`, the [`Micro::Attributes.new`](#microattributesnew) factory, or just `include Micro::Attributes` — composes recursively:

- `attribute :foo, accept: SomeMicroAttributesClass` automatically coerces a hash to that class.
- `attribute :foo do ... end` defines an anonymous nested class inline; the inline class inherits the outer's feature mix.
- Nested-attribute errors bubble up as `'is invalid'` markers, while the leaf retains the full rejection message. The same applies to ActiveModel validations.

There's no `Micro::Entity` wrapper — composition lives in `Micro::Attributes` itself.

## `Micro::Attributes.new`

A `Struct.new`-style factory that returns a fresh class wired with the requested features. The preset is `{ initialize: true, accept: true }` — override per-key by passing `false` (off), `true` (on), or a variant symbol (`:strict`):

```ruby
User = Micro::Attributes.new do
  attribute :name, accept: String
  attribute :age,  accept: Numeric
end

user = User.new(name: 'Rodrigo', age: 34)
user.name # 'Rodrigo'

bad = User.new(name: :rodrigo, age: '34')
bad.attributes_errors
# {
#   "name" => "expected to be a kind of String",
#   "age"  => "expected to be a kind of Numeric"
# }

# Strict + symbol keys + AM:
StrictUser = Micro::Attributes.new(
  initialize: :strict,
  accept: :strict,
  keys_as: :symbol,
  active_model: :validations
) do
  attribute :name, accept: String, validates: { presence: true }
  attribute :age,  accept: Numeric
end

StrictUser.new(name: 'X') # ArgumentError: missing keyword: :age
```

The same options work on `include Micro::Attributes.with(...)` — see [the hash-style configuration](#hash-style-configuration-for-microattributeswith) below.

[⬆️ Back to Top](#table-of-contents-)

## Hash-style configuration for `Micro::Attributes.with`

In addition to the positional symbol API ([`Micro::Attributes.with(:initialize, :accept)`](#microattributeswith)), `with` accepts a single hash describing the whole feature mix:

```ruby
Micro::Attributes.with(
  initialize:   true | :strict,
  accept:       true | :strict,
  diff:         true,
  keys_as:      :symbol | :string | :indifferent,
  active_model: :validations
)
```

- Omit a key (or pass `false` / `nil`) to disable a feature.
- `keys_as: :string` and `keys_as: :indifferent` are no-ops (that's the default behavior); only `:symbol` activates `KeysAsSymbol`.
- The positional API is fully supported — both forms can be mixed.

```ruby
class User
  include Micro::Attributes.with(initialize: true, accept: true, keys_as: :symbol)

  attribute :name, accept: String
end

# Layer extra features inline with the `with` class macro:
class StrictUser
  include Micro::Attributes.with(initialize: :strict, accept: :strict)
  with active_model: :validations

  attribute :name, accept: String, validates: { presence: true }
  attribute :age,  accept: Numeric
end
```

[⬆️ Back to Top](#table-of-contents-)

## Nested attributes via `accept:`

When `accept:` is another class that includes `Micro::Attributes` **and has `:initialize`**, hashes assigned to that attribute are auto-coerced into an instance of the target class. Already-built instances pass through unchanged. If the target lacks `:initialize` (you provide your own constructor), the hash passes through and the standard accept check applies — no auto-coercion.

```ruby
Address = Micro::Attributes.new do
  attribute :city,   accept: String
  attribute :postal, accept: String
end

Profile = Micro::Attributes.new do
  attribute :name,    accept: String
  attribute :address, accept: Address
end

profile = Profile.new(name: 'Rodrigo', address: { city: 'Rio', postal: '20000-000' })

profile.address.class # Address
profile.address.city  # 'Rio'

# Already-built instances pass through:
addr    = Address.new(city: 'Rio', postal: '20000-000')
profile = Profile.new(name: 'Rodrigo', address: addr)

profile.address.equal?(addr) # true
```

> **Note:** error surfacing through `attributes_errors?` / `attributes_errors` (and the deep-bubble marker) requires the **parent** to also include `:accept`. A parent without `:accept` will still coerce hashes into child instances, but it has no `attributes_errors` machinery to mirror descendant invalidity — `parent.child.attributes_errors?` may be true while the parent looks clean. Walk the tree explicitly in that case, or include `:accept` on the parent.

[⬆️ Back to Top](#table-of-contents-)

## Defining nested attributes inline (block form)

`attribute` accepts a block. The block defines an anonymous nested class with the **same feature mix** as the host — strict/symbol-keys/AM all propagate:

```ruby
Order = Micro::Attributes.new do
  attribute :id, accept: Integer

  attribute :customer do
    attribute :name,  accept: String
    attribute :email, accept: String
  end
end

order = Order.new(id: 1, customer: { name: 'Rodrigo', email: 'rodrigo@example.com' })
order.customer.name # 'Rodrigo'
```

The inline class uses the host's `Micro::Attributes.with(...)` module, so a `keys_as: :symbol` host yields a symbol-keyed inline child, an `initialize: :strict` host yields a strict inline child, and so on.

[⬆️ Back to Top](#table-of-contents-)

## Deep nesting & validation bubbling

Both forms (class-based via `accept:` and block-form) compose recursively to any depth. Each level carries its own `attributes_errors` / `errors`; any descendant invalidity is **mirrored** up the chain as a `'is invalid'` marker while the leaf retains the original message.

### Accept-error bubbling (no ActiveModel needed)

```ruby
City    = Micro::Attributes.new { attribute :name,    accept: String }
Address = Micro::Attributes.new { attribute :city,    accept: City    }
Profile = Micro::Attributes.new { attribute :address, accept: Address }

profile = Profile.new(address: { city: { name: 42 } })

# Leaf has the detail
profile.address.city.attributes_errors  # {"name" => "expected to be a kind of String"}

# Every ancestor mirrors the invalidity
profile.attributes_errors?              # true
profile.attributes_errors               # {"address" => "is invalid"}
profile.address.attributes_errors       # {"city" => "is invalid"}
```

### ActiveModel deep validation

When `active_model: :validations` (or `:activemodel_validations` positional) is in the feature mix, a `__validate_nested_entities__` validator is auto-registered. `parent.valid?` reflects deep descendant invalidity:

```ruby
Leaf = Micro::Attributes.new(active_model: :validations) do
  attribute :name, accept: String, validates: { presence: true }
end

Mid = Micro::Attributes.new(active_model: :validations) do
  attribute :leaf, accept: Leaf
end

Root = Micro::Attributes.new(active_model: :validations) do
  attribute :mid, accept: Mid
end

root = Root.new(mid: { leaf: { name: '' } })

root.valid?                  # false   — bubbled up
root.errors[:mid]            # ["is invalid"]
root.mid.errors[:leaf]       # ["is invalid"]
root.mid.leaf.errors[:name]  # ["can't be blank"]   ← detail at the leaf
```

Mixed trees work too — if a child has no AM, the validator falls back to checking its `attributes_errors?`:

```ruby
AcceptLeaf = Micro::Attributes.new do                      # no AM
  attribute :name, accept: String
end

AMRoot = Micro::Attributes.new(active_model: :validations) do
  attribute :leaf, accept: AcceptLeaf
end

AMRoot.new(leaf: { name: 42 }).valid?    # false — accept-error on the leaf bubbles to AM on root
```

The contract: **detail at the leaf, marker at every ancestor.** Walk the tree (`obj.mid.leaf.attributes_errors`) for the message; use `obj.attributes_errors?` / `obj.valid?` at the top to gate flow.

[⬆️ Back to Top](#table-of-contents-)

Every combination of `Micro::Entity` / `Micro::Entity::Strict` × default-keys / `KeysAsSymbol` × no-`ActiveModel` / `ActiveModelValidations` is covered by `test/micro/entity_matrix_test.rb`.

[⬆️ Back to Top](#table-of-contents-)

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-attributes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the Micro::Attributes project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-attributes/blob/main/CODE_OF_CONDUCT.md).
