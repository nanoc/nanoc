##### Requirements

# Rake etc
require 'rake'
require 'rake/gempackagetask'

# nanoc itself
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'nanoc'

##### General details

SUMMARY = 'a tool that runs on your local computer and compiles Markdown, ' +
          'Textile, Haml, ... documents into static web pages'
POST_INSTALL_MESSAGE = <<EOS
Thanks for installing nanoc 3.0! Here are some resources to help you get started:

* The tutorial at <http://nanoc.stoneship.org/help/tutorial/>
* The manual at <http://nanoc.stoneship.org/help/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 3.0 has a lot of new features, be sure to check out the nanoc blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
EOS

GemSpec = Gem::Specification.new do |s|
  s.name                  = 'nanoc'
  s.version               = Nanoc::VERSION
  s.platform              = Gem::Platform::RUBY
  s.summary               = SUMMARY
  s.description           = s.summary
  s.homepage              = 'http://nanoc.stoneship.org/'
  s.rubyforge_project     = 'nanoc'

  s.author                = 'Denis Defreyne'
  s.email                 = 'denis.defreyne@stoneship.org'

  s.post_install_message  = '-' * 78 + "\n" + POST_INSTALL_MESSAGE + '-' * 78

  s.required_ruby_version = '>= 1.8.5'

  s.has_rdoc              = true
  s.extra_rdoc_files      = [ 'README' ]
  s.rdoc_options          <<  '--title'   << 'nanoc'                    <<
                              '--main'    << 'README'                   <<
                              '--charset' << 'utf-8'                    <<
                              '--exclude' << 'lib/nanoc/cli/commands'   <<
                              '--exclude' << 'lib/nanoc/extra/vcses'    <<
                              '--exclude' << 'lib/nanoc/filters'        <<
                              '--exclude' << 'test'                     <<
                              '--line-numbers'

  s.files                 = %w( README LICENSE ChangeLog Rakefile ) + Dir[File.join('{bin,lib,vendor}', '**', '*')]
  s.executables           = [ 'nanoc' ]
  s.require_path          = 'lib'
  s.bindir                = 'bin'
end

Dir.glob('tasks/**/*.rake').each { |r| Rake.application.add_import r }

task :default => [ :fetch_dependencies, :test ]
