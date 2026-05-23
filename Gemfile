source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in u-attributes.gemspec
gemspec

gem "rake", "~> 13.0"

gem "u-case", "~> 4.5", ">= 4.5.1"

group :test do
  gem "minitest", "~> 5.0"
  gem "ostruct", "~> 0.6.3" if RUBY_VERSION >= "3.5"
  gem "simplecov", "~> 0.22.0", require: false
end
