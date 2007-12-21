##### Requirements

require 'rake'

require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'

require File.dirname(__FILE__) + '/lib/nanoc.rb'

##### General details

NAME    = 'nanoc'
VERS    = Nanoc::VERSION
SUMMARY = 'a tool that runs on your local computer and compiles Markdown, ' +
          'Textile, Haml, ... documents into static web pages'

HOMEPAGE  = 'http://nanoc.stoneship.org/'
EMAIL     = 'denis.defreyne@stoneship.org'

##### Cleaning

CLEAN.include [ 'tmp', 'test/fixtures/*/output/*', 'test/fixtures/*/tmp' ]
CLOBBER.include [ 'pkg' ]

##### Packaging

spec = Gem::Specification.new do |s|
  s.name        = NAME
  s.version     = VERS
  s.platform    = Gem::Platform::RUBY
  s.summary     = SUMMARY
  s.description = s.summary
  s.homepage    = HOMEPAGE
  s.email       = EMAIL

  s.required_ruby_version = '>= 1.8.2'

  s.has_rdoc      = false
  s.files         = %w( README LICENSE ChangeLog Rakefile ) + Dir['{bin,lib}/**/*']
  s.executables   = [ 'nanoc' ]
  s.require_path  = 'lib'
  s.bindir        = 'bin'
end

Rake::GemPackageTask.new(spec) { |task| }

task :install_gem do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall_gem do
  sh %{sudo gem uninstall #{NAME}}
end

### Testing

Rake::TestTask.new(:test) do |test|
  test.test_files = Dir['test/test_*.rb']
end

task :default => [ :test ]
