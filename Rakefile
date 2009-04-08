##### Requirements

# Rake etc
require 'rake'
require 'rake/gempackagetask'

# nanoc itself
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'nanoc'

##### General details

NAME      = 'nanoc'
VERS      = Nanoc::VERSION
SUMMARY   = 'a tool that runs on your local computer and compiles ' +
            'Markdown, Textile, Haml, ... documents into static web pages'
HOMEPAGE  = 'http://nanoc.stoneship.org/'

AUTHOR    = 'Denis Defreyne'
EMAIL     = 'denis.defreyne@stoneship.org'

MESSAGE   = <<EOS
Thanks for installing nanoc 2.2! Here are some resources to help you get started:

* The tutorial at <http://nanoc.stoneship.org/help/tutorial/>
* The manual at <http://nanoc.stoneship.org/help/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Be sure to check out the nanoc blog at <http://nanoc.stoneship.org/blog/> for
details about this release.

Enjoy!
EOS

##### Packaging

GemSpec = Gem::Specification.new do |s|
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
                              '--exclude' << 'doc'                      <<
                              '--exclude' << 'test'                     <<
                              '--exclude' << 'vendor'                   <<
                              '--line-numbers'

  s.files                 = %w( README LICENSE ChangeLog Rakefile ) + Dir[File.join('{bin,lib,vendor}', '**', '*')]
  s.executables           = [ 'nanoc' ]
  s.require_path          = 'lib'
  s.bindir                = 'bin'
end

Dir.glob('tasks/**/*.rake').each { |r| Rake.application.add_import r }

task :default => [ :fetch_dependencies, :test ]
