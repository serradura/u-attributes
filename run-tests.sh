#!/bin/bash

ACTIVEMODEL_VERSION='3.2' bundle update
ACTIVEMODEL_VERSION='3.2' bundle exec rake test

ACTIVEMODEL_VERSION='4.0' bundle update
ACTIVEMODEL_VERSION='4.0' bundle exec rake test

ACTIVEMODEL_VERSION='4.1' bundle update
ACTIVEMODEL_VERSION='4.1' bundle exec rake test

ACTIVEMODEL_VERSION='4.2' bundle update
ACTIVEMODEL_VERSION='4.2' bundle exec rake test

ACTIVEMODEL_VERSION='5.0' bundle update
ACTIVEMODEL_VERSION='5.0' bundle exec rake test

ACTIVEMODEL_VERSION='5.1' bundle update
ACTIVEMODEL_VERSION='5.1' bundle exec rake test

ACTIVEMODEL_VERSION='5.2' bundle update
ACTIVEMODEL_VERSION='5.2' bundle exec rake test
