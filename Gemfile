source 'https://rubygems.org'

# Declare your gem's dependencies in fileseries.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :development do
  gem "bundler"
  gem "ci_reporter_rspec"
  gem "rdoc", "~> 3.12"
  gem "rspec"
  gem "timecop", "0.3.5"
end

group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'rubocop', require: false
  gem 'rubocop-checkstyle_formatter'
end
