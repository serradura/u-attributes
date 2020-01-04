![Ruby](https://img.shields.io/badge/ruby-2.2+-ruby.svg?colorA=99004d&colorB=cc0066)
[![Gem](https://img.shields.io/gem/v/u-attributes.svg?style=flat-square)](https://rubygems.org/gems/u-attributes)
[![Build Status](https://travis-ci.com/serradura/u-attributes.svg?branch=master)](https://travis-ci.com/serradura/u-attributes)
[![Maintainability](https://api.codeclimate.com/v1/badges/b562e6b877a9edf4dbf6/maintainability)](https://codeclimate.com/github/serradura/u-attributes/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/b562e6b877a9edf4dbf6/test_coverage)](https://codeclimate.com/github/serradura/u-attributes/test_coverage)

μ-attributes (Micro::Attributes) <!-- omit in toc -->
================================

This gem allows defining read-only attributes, that is, your objects will have only getters to access their attributes data.

## Table of contents <!-- omit in toc -->
- [Required Ruby version](#required-ruby-version)
- [Installation](#installation)
- [Usage](#usage)
  - [How to require?](#how-to-require)
  - [How to define attributes?](#how-to-define-attributes)
  - [How to define multiple attributes?](#how-to-define-multiple-attributes)
  - [How to define attributes with a constructor to assign them?](#how-to-define-attributes-with-a-constructor-to-assign-them)
  - [How to inherit the attributes?](#how-to-inherit-the-attributes)
  - [How to query the attributes?](#how-to-query-the-attributes)
- [Built-in extensions](#built-in-extensions)
  - [ActiveModel::Validations extension](#activemodelvalidations-extension)
  - [Diff extension](#diff-extension)
  - [Initialize extension](#initialize-extension)
  - [Strict initialize extension](#strict-initialize-extension)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Required Ruby version

> \>= 2.2.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-attributes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install u-attributes

## Usage

### How to require?
```ruby
# Bundler will do it automatically, but if you desire to do a manual require.
# Use one of the following options:

require 'micro/attributes'

# or

require 'u-attributes'
```

### How to define attributes?
```ruby

# By default you must to define the class constructor.

class Person
  include Micro::Attributes

  attribute :name
  attribute :age

  def initialize(name: 'John Doe', age:)
    @name, @age = name, age
  end
end

person = Person.new(age: 21)

puts person.name # John Doe
puts person.age  # 21

# By design, the attributes expose only reader methods (getters).
# If you try to call a setter, you will see a NoMethodError.
#
# person.name = 'Rodrigo'
# NoMethodError (undefined method `name=' for #<Person:0x0000... @name="John Doe", @age=21>)

#------------------#
# self.attributes= #
#------------------#

# This protected method is added to make easier the assignment in a constructor.

class Person
  include Micro::Attributes

  attribute :name, 'John Doe' # .attribute() accepts a second arg as its default value
  attribute :age

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new(age: 20)

puts person.name # John Doe
puts person.age  # 20

#--------------#
# #attribute() #
#--------------#
#
# Use the #attribute() method with a valid attribute name to get its value

puts person.attribute(:name) # John Doe
puts person.attribute('age') # 20
puts person.attribute('foo') # nil

#
# If you pass a block, it will be executed only if the attribute is valid.

person.attribute(:name) { |value| puts value } # John Doe
person.attribute('age') { |value| puts value } # 20
person.attribute('foo') { |value| puts value } # !! Nothing happened, because of the attribute not exists.

#---------------#
# #attribute!() #
#---------------#
#
# Works like the #attribute() method, but will raise an exception when the attribute not exist.

puts person.attribute!('foo')                   # NameError (undefined attribute `foo)
person.attribute!('foo') { |value| puts value } # NameError (undefined attribute `foo)
```

### How to define multiple attributes?

```ruby

# Use .attributes with a list of attribute names.

class Person
  include Micro::Attributes

  attributes :age, name: 'John Doe' # Use a hash to define attributes with default values

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new(age: 32)

puts person.name # 'John Doe'
puts person.age  # 32
```

### How to define attributes with a constructor to assign them?
A: Use `Micro::Attributes.to_initialize`

```ruby
class Person
  include Micro::Attributes.to_initialize

  attributes :age, name: 'John Doe'
end

person = Person.new(age: 18)

puts person.name # John Doe
puts person.age  # 18

##############################################
# Assigning new values to get a new instance #
##############################################

#-------------------#
# #with_attribute() #
#-------------------#

another_person = person.with_attribute(:age, 21)

puts another_person.name           # John Doe
puts another_person.age            # 21
puts another_person.equal?(person) # false

#--------------------#
# #with_attributes() #
#--------------------#
#
# Use it to assign multiple attributes

other_person = person.with_attributes(name: 'Serradura', age: 32)

puts other_person.name           # Serradura
puts other_person.age            # 32
puts other_person.equal?(person) # false

# If you pass a value different of a Hash, an ArgumentError will be raised.
#
# Person.new(1)
# ArgumentError (argument must be a Hash)

#--------------------#
# Strict initializer #
#--------------------#

# Use .to_initialize! to forbids an instantiation without all keywords.

class StrictPerson
  include Micro::Attributes.to_initialize!

  attributes :age, name: 'John Doe'
end

StrictPerson.new({})

# The code above will raise:
# ArgumentError (missing keyword: :age)

person_without_age = StrictPerson.new(age: nil)

p person_without_age.name # "John Doe"
p person_without_age.age  # nil

# Except for this validation when initializing,
# the `to_initialize!` method will works in the same ways of `to_initialize`.
```

### How to inherit the attributes?

```ruby
class Person
  include Micro::Attributes.to_initialize

  attributes :age, name: 'John Doe'
end

class Subclass < Person # Will preserve the parent class attributes
  attribute :foo
end

instance = Subclass.new({})

puts instance.name              # John Doe
puts instance.respond_to?(:age) # true
puts instance.respond_to?(:foo) # true

#---------------------------------#
# .attribute!() or .attributes!() #
#---------------------------------#

# The methods above allow redefining the attributes default data

class AnotherSubclass < Person
  attribute! :name, 'Alfa'
end

alfa_person = AnotherSubclass.new({})

p alfa_person.name # "Alfa"
p alfa_person.age  # nil

class SubSubclass < Subclass
  attributes! name: 'Beta', age: 0
end

beta_person = SubSubclass.new({})

p beta_person.name # "Beta"
p beta_person.age  # 0
```

### How to query the attributes?

```ruby
class Person
  include Micro::Attributes

  attributes :age, name: 'John Doe'

  def initialize(options)
    self.attributes = options
  end
end

#---------------#
# .attributes() #
#---------------#

p Person.attributes # ["name", "age"]

#---------------#
# .attribute?() #
#---------------#

puts Person.attribute?(:name)  # true
puts Person.attribute?('name') # true
puts Person.attribute?('foo') # false
puts Person.attribute?(:foo)  # false

# ---

person = Person.new(age: 20)

#---------------#
# #attribute?() #
#---------------#

puts person.attribute?(:name)  # true
puts person.attribute?('name') # true
puts person.attribute?('foo') # false
puts person.attribute?(:foo)  # false

#---------------#
# #attributes() #
#---------------#

p person.attributes                   # {"age"=>20, "name"=>"John Doe"}
p Person.new(name: 'John').attributes # {"age"=>nil, "name"=>"John"}

#---------------------#
# #attributes(*names) #
#---------------------#

# Slices the attributes to include only the given keys.
# Returns a hash containing the given keys (in their types).

p person.attributes(:age)             # {age: 20}
p person.attributes(:age, :name)      # {age: 20, name: "John Doe"}
p person.attributes('age', 'name')    # {"age"=>20, "name"=>"John Doe"}
```

## Built-in extensions

You can use the method `Micro::Attributes.features()` or `Micro::Attributes.with()` to combine and require only the features that better fit your needs.

But, if you desire...
1. only one feature, use the `Micro::Attributes.feature()` method.
2. except one or more features, use the `Micro::Attributes.without()` method.

```ruby
#===========================#
# Loading specific features #
#===========================#

class Job
  include Micro::Attributes.feature(:diff)

  attribute :id
  attribute :state, 'sleeping'

  def initialize(options)
    self.attributes = options
  end
end

#======================#
# Loading all features #
#         ---          #
#======================#

class Job
  include Micro::Attributes.features

  attributes :id, state: 'sleeping'
end

# Note:
# If `Micro::Attributes.features()` be invoked without arguments, a module with all features will be returned.

#----------------------------------------------------------------------------#
# Using the .with() method alias and adding the strict initialize extension. #
#----------------------------------------------------------------------------#
class Job
  include Micro::Attributes.with(:strict_initialize, :diff)

  attributes :id, state: 'sleeping'
end

# Note:
# The method `Micro::Attributes.with()` will raise an exception if no arguments/features were declared.
#
# class Job
#   include Micro::Attributes.with() # ArgumentError (Invalid feature name! Available options: diff, initialize, activemodel_validations)
# end

#===================================#
# Alternatives to the methods above #
#===================================#

#---------------------------------------#
# Via Micro::Attributes.to_initialize() #
#---------------------------------------#
class Job
  include Micro::Attributes.to_initialize(diff: true, activemodel_validations: true)

  # Same of `include Micro::Attributes.with(:initialize, :diff, :activemodel_validations)`
end

#----------------------------------------#
# Via Micro::Attributes.to_initialize!() #
#----------------------------------------#
class Job
  include Micro::Attributes.to_initialize!(diff: false, activemodel_validations: true)

  # Same of `include Micro::Attributes.with(:strict_initialize, :activemodel_validations)`
end

#=====================================#
# Loading except one or more features #
#         -----                       #
#=====================================#

class Job
  include Micro::Attributes.without(:diff)

  attributes :id, state: 'sleeping'
end

# Note:
# The method `Micro::Attributes.without()` returns `Micro::Attributes` if all features extensions were used.
```

### ActiveModel::Validations extension

If your application uses ActiveModel as a dependency (like a regular Rails app). You will be enabled to use the `actimodel_validations` extension.

```ruby
class Job
  # include Micro::Attributes.with(:initialize, :activemodel_validations)
  # include Micro::Attributes.features(:initialize, :activemodel_validations)
  include Micro::Attributes.to_initialize(activemodel_validations: true)

  attributes :id, state: 'sleeping'
  validates! :id, :state, presence: true
end

Job.new({}) # ActiveModel::StrictValidationFailed (Id can't be blank)

job = Job.new(id: 1)

p job.id    # 1
p job.state # "sleeping"
```

### Diff extension

Provides a way to track changes in your object attributes.

```ruby
require 'securerandom'

class Job
  # include Micro::Attributes.with(:initialize, :diff)
  # include Micro::Attributes.to_initialize(diff: true)
  include Micro::Attributes.features(:initialize, :diff)

  attributes :id, state: 'sleeping'
end

job = Job.new(id: SecureRandom.uuid())

p job.id    # A random UUID generated from SecureRandom.uuid(). e.g: "e68bcc74-b91c-45c2-a904-12f1298cc60e"
p job.state # "sleeping"

job_running = job.with_attribute(:state, 'running')

p job_running.state # "running"

job_changes = job.diff_attributes(job_running)

#-----------------------------#
# #present?, #blank?, #empty? #
#-----------------------------#

p job_changes.present? # true
p job_changes.blank?   # false
p job_changes.empty?   # false

#-----------#
# #changed? #
#-----------#
p job_changes.changed? # true

p job_changes.changed?(:id)    # false

p job_changes.changed?(:state) # true
p job_changes.changed?(:state, from: 'sleeping', to: 'running') # true

#----------------#
# #differences() #
#----------------#
p job_changes.differences # {"state"=> {"from" => "sleeping", "to" => "running"}}
```

### Initialize extension

1. Creates a constructor to assign the attributes.
2. Adds methods to build new instances when some data was assigned.

```ruby
class Job
  # include Micro::Attributes.with(:initialize)
  # include Micro::Attributes.feature(:initialize)
  # include Micro::Attributes.features(:initialize)
  include Micro::Attributes.to_initialize

  attributes :id, :state
end

job_null = Job.new({})

p job.id    # nil
p job.state # nil

job = Job.new(id: 1, state: 'sleeping')

p job.id    # 1
p job.state # "sleeping"

##############################################
# Assigning new values to get a new instance #
##############################################

#-------------------#
# #with_attribute() #
#-------------------#

new_job = job.with_attribute(:state, 'running')

puts new_job.id          # 1
puts new_job.state       # running
puts new_job.equal?(job) # false

#--------------------#
# #with_attributes() #
#--------------------#
#
# Use it to assign multiple attributes

other_job = job.with_attributes(id: 2, state: 'killed')

puts other_job.id          # 2
puts other_job.state       # killed
puts other_job.equal?(job) # false
```

### Strict initialize extension

1. Creates a constructor to assign the attributes.
2. Adds methods to build new instances when some data was assigned.
3. **Forbids missing keywords**.

```ruby
class Job
  # include Micro::Attributes.with(:strict_initialize)
  # include Micro::Attributes.feature(:strict_initialize)
  # include Micro::Attributes.features(:strict_initialize)
  include Micro::Attributes.to_initialize!

  attributes :id, :state
end
#----------------------------------------------------------------------------#
# The strict_initialize extension will require all the keys when initialize. #
#----------------------------------------------------------------------------#

Job.new({})

# The code above will raise:
# ArgumentError (missing keywords: :id, :state)

#---------------------------#
# Samples passing some data #
#---------------------------#

job_null = Job.new(id: nil, state: nil)

p job.id    # nil
p job.state # nil

job = Job.new(id: 1, state: 'sleeping')

p job.id    # 1
p job.state # "sleeping"


# Note:
#   This extension works like the `initialize` extension.
#   So, look at its section to understand all the other features.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-attributes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Attributes project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-attributes/blob/master/CODE_OF_CONDUCT.md).
