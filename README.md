# μ-attributes (Micro::Attributes)

This gem allows defining read-only attributes, that is, your objects will have only getters to access their attributes data.

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

  attribute :name
  attribute :age

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new('name' => 'John', age: 20)

puts person.name # John
puts person.age  # 20
```

### How to define multiple attributes?

```ruby

# Use .attributes with a list of attribute names.

class Person
  include Micro::Attributes

  attributes :name, :age

  def initialize(options)
    self.attributes = options
  end
end

person = Person.new('Serradura', 32)

puts person.name # Serradura
puts person.age  # 32
```

### How to define attributes with a constructor to assign them?
A: Use `Micro::Attributes.to_initialize`

```ruby
class Person
  include Micro::Attributes.to_initialize

  attributes :age, name: 'John Doe' # Use a hash to define a default value

  # attribute name: 'John Doe'
  # attribute :age
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

#########################################################
# Inheritance will preserve the parent class attributes #
#########################################################

class Subclass < Person
  attribute :foo
end

instance = Subclass.new({})

puts instance.name              # John Doe
puts instance.respond_to?(:age) # true
puts instance.respond_to?(:foo) # true

##############################################################
# Inheritance allows to redefine the attributes default data #
##############################################################

class AnotherSubclass < Person
  attribute! name: 'Alfa'
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/micro-attributes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Attributes project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/micro-attributes/blob/master/CODE_OF_CONDUCT.md).
