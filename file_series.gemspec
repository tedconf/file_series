
$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
#require 'file_series/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "file_series"
  s.version = "0.6.0"
  s.authors = ["Alex Dean"]
  s.email = "alex@crackpot.org"
  s.homepage = "http://github.com/tedconf/file_series"
  s.summary = "Write to a series of time-based files."
  s.description = "Automatically start writing to a new file every X seconds without any locking or file moving/renaming."
  s.licenses = ["MIT"]
  s.date = "2016-05-13"

  s.rubygems_version = "2.2.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".autotest",
    ".document",
    ".rspec",
    ".ruby-gemset",
    ".ruby-version",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "file_series.gemspec",
    "lib/file_series.rb",
    "script/jenkins.sh",
    "spec/file_series_spec.rb",
    "spec/spec_helper.rb"
  ]


  s.add_dependency 'rake'
  s.add_dependency 'rspec', '~> 2.99'
  s.add_dependency 'ci_reporter_rspec', '>= 0'
  s.add_dependency 'rdoc', '~> 3.12'
  s.add_dependency 'timecop', '= 0.3.5'
  s.add_dependency 'brakeman', '>= 0'
  s.add_dependency 'bundler-audit', '>= 0'
  s.add_dependency 'rubocop', '>= 0'
  s.add_dependency 'rubocop-checkstyle_formatter', '>= 0'
end
