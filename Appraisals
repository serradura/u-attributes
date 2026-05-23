if RUBY_VERSION < "3.1"
  appraise "rails-6-0" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"

      gem "minitest", "5.26.1"
      gem "activemodel", "~> 6.0.0"
    end
  end

  appraise "rails-6-1" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"

      gem "minitest", "5.26.1"
      gem "activemodel", "~> 6.1.0"
    end
  end
end

if RUBY_VERSION >= "2.7" && RUBY_VERSION < "3.4"
  appraise "rails-7-0" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"
      gem "securerandom", "~> 0.3.2"

      gem "minitest", "5.26.1"
      gem "activemodel", "~> 7.0.0"
    end
  end

  appraise "rails-7-1" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"
      gem "securerandom", "~> 0.3.2"

      gem "minitest", "5.26.1"
      gem "activemodel", "~> 7.1.0"
    end
  end
end

if RUBY_VERSION >= "3.1" && RUBY_VERSION < "4.0"
  appraise "rails-7-2" do
    group :test do
      gem "minitest", "~> 5.27"
      gem "activemodel", "~> 7.2.0"
    end
  end
end

if RUBY_VERSION >= "3.2" && RUBY_VERSION < "4.0"
  appraise "rails-8-0" do
    group :test do
      gem "ostruct", "~> 0.6.3"
      gem "minitest", "~> 5.27"
      gem "activemodel", "~> 8.0.0"
    end
  end
end

if RUBY_VERSION >= "3.3.0"
  minitest_version = (RUBY_VERSION >= "4.0.0") ? "~> 6.0" : "~> 5.27"

  appraise "rails-8-1" do
    group :test do
      gem "ostruct", "~> 0.6.3"
      gem "minitest", minitest_version
      gem "activemodel", "~> 8.1.0"
    end
  end

  appraise "rails-edge" do
    group :test do
      gem "ostruct", "~> 0.6.3"
      gem "minitest", minitest_version
      gem "activemodel", github: "rails/rails", branch: "main"
    end
  end
end
