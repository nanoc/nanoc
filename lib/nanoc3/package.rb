require 'singleton'

module Nanoc3

  # Nanoc3::Package is a singleton that contains metadata about the nanoc
  # project, which is used for packaging releases.
  class Package

    include Singleton

    # Returns a Gem::Specification used for packaging.
    def gem_spec
      @gem_spec ||= Gem::Specification.new do |s|
        s.name                  = 'nanoc3'
        s.version               = Nanoc3::VERSION
        s.platform              = Gem::Platform::RUBY
        s.summary               = 'a tool that runs on your local computer ' +
                                  'and compiles Markdown, Textile, Haml, ' +
                                  '... documents into static web pages'
        s.description           = s.summary
        s.homepage              = 'http://nanoc.stoneship.org/'
        s.rubyforge_project     = 'nanoc3'

        s.author                = 'Denis Defreyne'
        s.email                 = 'denis.defreyne@stoneship.org'

        s.post_install_message  = <<EOS
------------------------------------------------------------------------------
Thanks for installing nanoc 3.0! Here are some resources to help you get started:

* The tutorial at <http://nanoc.stoneship.org/help/tutorial/>
* The manual at <http://nanoc.stoneship.org/help/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 3.0 has a lot of new features, be sure to check out the nanoc blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
------------------------------------------------------------------------------
EOS

        s.required_ruby_version = '>= 1.8.5'

        s.has_rdoc              = true
        s.extra_rdoc_files      = [ 'README' ]
        s.rdoc_options          <<  '--title'   << 'nanoc'                    <<
                                    '--main'    << 'README'                   <<
                                    '--charset' << 'utf-8'                    <<
                                    '--exclude' << 'lib/nanoc3/cli/commands'  <<
                                    '--exclude' << 'lib/nanoc3/extra/vcses'   <<
                                    '--exclude' << 'lib/nanoc3/filters'       <<
                                    '--exclude' << 'test'                     <<
                                    '--line-numbers'

        s.files                 = %w( README LICENSE ChangeLog Rakefile ) +
                                  Dir[File.join('{bin,lib,vendor}', '**', '*')]
        s.executables           = [ 'nanoc3' ]
        s.require_path          = 'lib'
        s.bindir                = 'bin'
      end
    end

  end

end
