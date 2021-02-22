#!/bin/bash

RUBY_V=$(ruby -v)

function run_with_bundler {
  rm Gemfile.lock

  if [ ! -z "$1" ]; then
    bundle_cmd="bundle _$1_"
  else
    bundle_cmd="bundle"
  fi

  eval "$2 $bundle_cmd update"
  eval "$2 $bundle_cmd exec rake test"
}

function run_with_am_version_and_bundler {
  run_with_bundler "$2" "ACTIVEMODEL_VERSION=$1"
}

RUBY_2_2345="ruby 2.[2345]."

if [[ $RUBY_V =~ $RUBY_2_2345 ]]; then
  run_with_bundler "$BUNDLER_V1"

  run_with_am_version_and_bundler "3.2" "$BUNDLER_V1"
  run_with_am_version_and_bundler "4.0" "$BUNDLER_V1"
  run_with_am_version_and_bundler "4.1" "$BUNDLER_V1"
  run_with_am_version_and_bundler "4.2" "$BUNDLER_V1"
  run_with_am_version_and_bundler "5.0" "$BUNDLER_V1"
  run_with_am_version_and_bundler "5.1" "$BUNDLER_V1"
  run_with_am_version_and_bundler "5.2" "$BUNDLER_V1"
fi

RUBY_2_567="ruby 2.[567]."
RUBY_3_x_x="ruby 3.0."

if [[ $RUBY_V =~ $RUBY_2_567 ]] || [[ $RUBY_V =~ $RUBY_3_x_x ]]; then
  gem install bundler -v ">= 2" --no-doc

  run_with_bundler
  run_with_am_version_and_bundler "6.0"
  run_with_am_version_and_bundler "6.1"
fi
