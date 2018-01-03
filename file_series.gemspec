
$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'file_series/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "file_series"
  s.version = FileSeries::VERSION
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
  s.files = Dir['lib/**/*', 'LICENSE.txt', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']
end
