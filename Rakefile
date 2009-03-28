##### Requirements

# Rake etc
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

# nanoc itself
require File.dirname(__FILE__) + '/lib/nanoc.rb'

##### Test Ruby 1.9

if RUBY_VERSION >= '1.9'
  # Check presence of vendor/mocha
  unless File.directory?('vendor/mocha')
    warn "You appear to be running Ruby 1.9. Please make sure that, before " +
         "running the tests, you have a version of mocha that is " +
         "compatible with Ruby 1.9."
  end
end

##### General details

NAME      = 'nanoc'
VERS      = Nanoc::VERSION
SUMMARY   = 'a tool that runs on your local computer and compiles ' +
            'Markdown, Textile, Haml, ... documents into static web pages'
HOMEPAGE  = 'http://nanoc.stoneship.org/'

AUTHOR    = 'Denis Defreyne'
EMAIL     = 'denis.defreyne@stoneship.org'

MESSAGE   = <<EOS
Thanks for installing nanoc 2.1! Here are some resources to help you get started:

* The tutorial at <http://nanoc.stoneship.org/help/tutorial/>
* The manual at <http://nanoc.stoneship.org/help/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 2.1 has a lot of new features, be sure to check out the nanoc blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
EOS

##### Cleaning

CLEAN.include([
  'coverage',
  'rdoc',
  'tmp',
  File.join('test', 'fixtures', '*', 'output', '*'),
  File.join('test', 'fixtures', '*', 'tmp')
])
CLOBBER.include([ 'pkg' ])

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

  s.post_install_message  = '-' * 78 + "\n" + MESSAGE + '-' * 78

  s.rubyforge_project     = 'nanoc'

  s.required_ruby_version = '>= 1.8.5'

  s.has_rdoc              = true
  s.extra_rdoc_files      = [ 'README' ]
  s.rdoc_options          <<  '--title'   << 'nanoc'                    <<
                              '--main'    << 'README'                   <<
                              '--charset' << 'utf-8'                    <<
                              '--exclude' << 'lib/nanoc/cli/commands'   <<
                              '--exclude' << 'lib/nanoc/binary_filters' <<
                              '--exclude' << 'lib/nanoc/extra/vcses'    <<
                              '--exclude' << 'lib/nanoc/filters'        <<
                              '--exclude' << 'test'                     <<
                              '--line-numbers'

  s.files                 = %w( README LICENSE ChangeLog Rakefile ) + Dir[File.join('{bin,lib}', '**', '*')]
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
  task.rdoc_dir = 'rdoc'
  task.options = spec.rdoc_options
end

### Testing

task :rcov do
  sh %{rcov test/**/test_*.rb -I test -x /Library}
end

Rake::TestTask.new(:test) do |task|
  ENV['QUIET'] = 'true'

  task.libs       = [ 'lib', 'test' ]
  task.test_files = Dir[ 'test/**/test_*.rb' ]
end

task :default => [ :test ]
