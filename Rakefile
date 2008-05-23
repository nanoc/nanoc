##### Requirements

require 'rake'

require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

require File.dirname(__FILE__) + '/lib/nanoc.rb'

##### General details

NAME    = 'nanoc'
VERS    = Nanoc::VERSION
SUMMARY = 'a tool that runs on your local computer and compiles Markdown, ' +
          'Textile, Haml, ... documents into static web pages'
HOMEPAGE  = 'http://nanoc.stoneship.org/'

AUTHOR    = 'Denis Defreyne'
EMAIL     = 'denis.defreyne@stoneship.org'

##### Cleaning

CLEAN.include [ 'tmp', 'test/fixtures/*/output/*', 'test/fixtures/*/tmp' ]
CLOBBER.include [ 'pkg' ]

##### Packaging

spec = Gem::Specification.new do |s|
  s.name                  = NAME
  s.version               = VERS
  s.platform              = Gem::Platform::RUBY
  s.summary               = SUMMARY
  s.description           = s.summary
  s.homepage              = HOMEPAGE

  s.author                = AUTHOR
  s.email                 = EMAIL

  s.rubyforge_project     = 'nanoc'

  s.required_ruby_version = '>= 1.8.5'

  s.has_rdoc              = true
  s.extra_rdoc_files      = [ 'README' ]
  s.rdoc_options          <<  '--title'   << 'nanoc'                  <<
                              '--main'    << 'README'                 <<
                              '--charset' << 'utf-8'                  <<
                              '--exclude' << 'lib/nanoc/data_sources' <<
                              '--exclude' << 'lib/nanoc/filters'      <<
                              '--exclude' << 'lib/nanoc/routers'      <<
                              '--exclude' << 'test'                   <<
                              '--line-numbers'

  s.files                 = %w( README LICENSE ChangeLog Rakefile ) + Dir['{bin,lib}/**/*']
  s.executables           = [ 'nanoc' ]
  s.require_path          = 'lib'
  s.bindir                = 'bin'
end

Rake::GemPackageTask.new(spec) { |task| }

task :install_gem do
  sh %{rake package}
  sh %{gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall_gem do
  sh %{gem uninstall #{NAME}}
end

### Documentation

Rake::RDocTask.new do |task|
  task.rdoc_files.include(spec.extra_rdoc_files + [ 'lib' ])
  task.options = spec.rdoc_options
end

### Testing

Rake::TestTask.new(:test) do |task|
  task.test_files = Dir['test/**/test_*.rb']
end

task :default => [ :test ]
