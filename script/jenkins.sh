#!/bin/bash

# Template Jenkins Wrapper for Language: 'Ruby'

# Setup our ruby and gemset
source /usr/local/rvm/scripts/rvm
type rvm | head -1

# Use our gemset (create it if it doesn't already exist)
ruby_version=`cat .ruby-version | tr -d '\n'`
ruby_gemset=`cat .ruby-gemset | tr -d '\n'`

rvm use "${ruby_version}@${ruby_gemset}" --create

# Make sure bundler is installed for this ruby version/gemset
gem list bundler -i >/dev/null 2>&1
if [ $? -eq 1 ]; then
  echo "Installing bundler"
  gem install bundler
fi

export DB_DATABASE=''

# Exit immediately if any single command fails
set -e

# use jenkins-specific secrets file if it exists
if [ -e $WORKSPACE/config/secrets.jenkins.yml ]; then
  cp $WORKSPACE/config/secrets.jenkins.yml $WORKSPACE/config/secrets.yml
fi

# Ensure we have ruby
ruby --version
echo "Ruby Gemset:"
rvm current
echo ""

# Print all commands after expansion.  Note that you can put this earlier
# in the script, but rvm prints out a wall-o-text.
set -x

# Update all our gems
bundle install

# Good to know the path
echo "PATH is ${PATH}"

rm -Rf build/*
rm -f checkstyle.xml Gemfile.lock

# Security check
ignores=""
bundle-audit update; bundle-audit check --ignore=${ignores}

# Run the tests
export COVERAGE=on
bundle exec rake spec

# Static checking
bundle exec rubocop \
  --require rubocop/formatter/checkstyle_formatter \
  --display-cop-names \
  --format clang \
  --format RuboCop::Formatter::CheckstyleFormatter \
  --out tmp/checkstyle.xml

# Security scan
# See http://brakemanscanner.org/docs/ignoring_false_positives/ to ignore anything reported here.
# brakeman -z

exit 0
