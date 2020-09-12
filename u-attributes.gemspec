
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'micro/attributes/version'

Gem::Specification.new do |spec|
  spec.name          = 'u-attributes'
  spec.version       = Micro::Attributes::VERSION
  spec.authors       = ['Rodrigo Serradura']
  spec.email         = ['rodrigo.serradura@gmail.com']

  spec.summary       = %q{Create "immutable" objects. No setters, just getters!}
  spec.description   =
    "This gem allows you to define \"immutable\" objects, and your objects will have only getters and no setters. "\
    "So, if you change some object attribute, you will have a new object instance. " \
    "That is, you transform the object instead of modifying it."
  spec.homepage      = 'https://github.com/serradura/u-attributes'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|assets)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'kind', '>= 3.0', '< 5.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0'
end
