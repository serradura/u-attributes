<p align="center">
  <img src="./assets/u-attributes_logo_v1.png" alt='Create "immutable" objects. No setters, just getters!'>

  <p align="center"><i>Create "immutable" objects. No setters, just getters!</i></p>
  <br>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ruby-2.2+-ruby.svg?colorA=99004d&colorB=cc0066" alt="Ruby">

  <a href="https://rubygems.org/gems/u-attributes">
    <img alt="Gem" src="https://img.shields.io/gem/v/u-attributes.svg?style=flat-square">
  </a>

  <a href="https://travis-ci.com/serradura/u-attributes">
    <img alt="Build Status" src="https://travis-ci.com/serradura/u-attributes.svg?branch=main">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-attributes/maintainability">
    <img alt="Maintainability" src="https://api.codeclimate.com/v1/badges/b562e6b877a9edf4dbf6/maintainability">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-attributes/test_coverage">
    <img alt="Test Coverage" src="https://api.codeclimate.com/v1/badges/b562e6b877a9edf4dbf6/test_coverage">
  </a>
</p>

This gem allows you to define "immutable" objects, and your objects will have only getters and no setters.
So, if you change [[1](#with_attribute)] [[2](#with_attributes)] some object attribute, you will have a new object instance. That is, you transform the object instead of modifying it.

# Table of contents <!-- omit in toc -->
- [Installation](#installation)
- [Compatibility](#compatibility)
- [Usage](#usage)
  - [How to define attributes?](#how-to-define-attributes)
    - [`Micro::Attributes#attributes=`](#microattributesattributes)
      - [How to extract attributes from an object or hash?](#how-to-extract-attributes-from-an-object-or-hash)
      - [Is it possible to define an attribute as required?](#is-it-possible-to-define-an-attribute-as-required)
    - [`Micro::Attributes#attribute`](#microattributesattribute)
    - [`Micro::Attributes#attribute!`](#microattributesattribute-1)
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
      - [`#attributes(with:, without)`](#attributeswith-without)
    - [`#defined_attributes`](#defined_attributes)
- [Built-in extensions](#built-in-extensions)
  - [Picking specific features](#picking-specific-features)
    - [`Micro::Attributes.with`](#microattributeswith)
    - [`Micro::Attributes.without`](#microattributeswithout)
  - [Picking all the features](#picking-all-the-features)
  - [Extensions](#extensions)
    - [`ActiveModel::Validation` extension](#activemodelvalidation-extension)
      - [`.attribute()` options](#attribute-options)
    - [Diff extension](#diff-extension)
    - [Initialize extension](#initialize-extension)
      - [Strict mode](#strict-mode)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

# Installation

Add this line to your application's Gemfile and `bundle install`:

```ruby
gem 'u-attributes'
```

# Compatibility

| u-attributes   | branch  | ruby     |  activemodel  |
| -------------- | ------- | -------- | ------------- |
| 2.3.0          | main    | >= 2.2.0 | >= 3.2, < 6.1 |
| 1.2.0          | v1.x    | >= 2.2.0 | >= 3.2, < 6.1 |

> **Note**: The activemodel is an optional dependency, this module [can be enabled](#activemodelvalidation-extension) to validate the attributes.

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

You can extract attributes using the `extract_attributes_from` method, it will try to fetch attributes from the
object using either the `object[attribute_key]` accessor or the reader method `object.attribute_key`.

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

> **Note:** This method can't define default values. To do this, use the `#attribute()` method.

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

``` ruby
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

Use the `keys_as:` option with `Symbol` or `String` to transform the attributes hash keys.

```ruby
person1 = Person.new(age: 20)
person1.attributes(keys_as: Symbol) # {:age=>20, :first_name=>"John", :last_name=>"Doe"}

person2 = Person.new(first_name: 'Rodrigo', last_name: 'Rodrigues')
person2.attributes(keys_as: String) # {"age"=>nil, "first_name"=>"Rodrigo", "last_name"=>"Rodrigues"}
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

#### `#attributes(with:, without)`

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

Micro::Attributes.with(initialize: :strict)

Micro::Attributes.with(:diff, :initialize)

Micro::Attributes.with(:diff, initialize: :strict)

Micro::Attributes.with(:activemodel_validations)

Micro::Attributes.with(:activemodel_validations, :diff)

Micro::Attributes.with(:activemodel_validations, :diff, initialize: :strict)
```

The method `Micro::Attributes.with()` will raise an exception if no arguments/features were declared.

```ruby
class Job
  include Micro::Attributes.with() # ArgumentError (Invalid feature name! Available options: :activemodel_validations, :diff, :initialize)
end
```

### `Micro::Attributes.without`

Picking *except* one or more features

```ruby
Micro::Attributes.without(:diff) # will load :activemodel_validations and initialize: :strict

Micro::Attributes.without(initialize: :strict) # will load :activemodel_validations and :diff
```

## Picking all the features

```ruby
Micro::Attributes.with_all_features
```

[⬆️ Back to Top](#table-of-contents-)

## Extensions

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

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-attributes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the Micro::Attributes project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-attributes/blob/main/CODE_OF_CONDUCT.md).
