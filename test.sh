#!/bin/bash

source $(dirname $0)/.travis.sh

echo ''
echo 'Resetting Gemfile'
echo ''

rm Gemfile.lock

bundle
