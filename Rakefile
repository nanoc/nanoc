require 'rake'

require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'

require File.dirname(__FILE__) + '/lib/nanoc.rb'

#####

NAME    = 'nanoc'
VERS    = Nanoc::VERSION
SUMMARY = 'a CMS that doesn\'t run on your server'

HOMEPAGE  = 'http://stoneship.org/software/nanoc'
EMAIL     = 'denis.defreyne@stoneship.org'

#####

CLEAN.include [ '*.gem', 'pkg', 'tmp', 'test/fixtures/*/output/*' ]

spec = Gem::Specification.new do |s|
  s.name        = NAME
  s.version     = VERS
  s.platform    = Gem::Platform::RUBY
  s.summary     = SUMMARY
  s.description = s.summary
  s.homepage    = HOMEPAGE
  s.email       = EMAIL

  s.add_dependency('erubis')
  s.required_ruby_version = '>= 1.8.2'

  s.has_rdoc      = false
  s.files         = %w( README LICENSE Rakefile ) + Dir['{bin,lib}/**/*']
  s.executables   = [ 'nanoc' ]
  s.require_path  = 'lib'
  s.bindir        = 'bin'
end

Rake::GemPackageTask.new(spec) do |task|
  task.need_tar = true
  task.gem_spec = spec
end

Rake::TestTask.new(:test) do |test|
  test.test_files = Dir['test/test_*.rb']
end

#####

task :default => [ :test ]

task :install_gem do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall_gem do
  sh %{sudo gem uninstall #{NAME}}
end
