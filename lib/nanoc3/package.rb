# encoding: utf-8

require 'singleton'

module Nanoc3

  # Nanoc3::Package is a singleton that contains metadata about the nanoc
  # project, which is used for packaging releases.
  class Package

    include Singleton

    # The name of the application.
    def name
      'nanoc3'
    end

    # The files to include in the package. This is also the list of files that
    # will be included in the documentation (with the exception of the files
    # in undocumented_files).
    def files
      @files ||= (%w( ChangeLog LICENSE NEWS.rdoc Rakefile README.rdoc ) +
        Dir['bin/**/*'] +
        Dir['lib/**/*']
    end

    # The files that are included in the documentation by default.
    def files_documented_by_default
      Dir['lib/**/*'].reject { |f| File.directory?(f) }
    end

    # The files that should not be included in the documentation.
    def files_not_in_documentation
      Dir['lib/**/*.rake']
    end

    # The files that should be included in the documentation.
    def files_in_documentation
      files - files_not_in_documentation
    end

    # The files that are not documented by RDoc by default, but should still
    # be included in the documentation.
    def extra_rdoc_files
      files_in_documentation - files_documented_by_default
    end

    # The name of the file that should be used as entry point for the
    # documentation.
    def main_documentation_file
      'README.rdoc'
    end

    # The Gem::Specification used for packaging.
    def gem_spec
      @gem_spec ||= Gem::Specification.new do |s|
        s.name                  = self.name
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

* The tutorial at <http://nanoc.stoneship.org/tutorial/>
* The manual at <http://nanoc.stoneship.org/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 3.0 has a lot of new features, be sure to check out the nanoc blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
------------------------------------------------------------------------------
EOS

        s.required_ruby_version = '>= 1.8.5'
        s.add_dependency('cri', '>= 1.0.0')

        s.has_rdoc              = true
        s.extra_rdoc_files      = self.extra_rdoc_files
        s.rdoc_options          = []
        s.rdoc_options          += [ '--title', self.name                    ]
        s.rdoc_options          += [ '--main',  self.main_documentation_file ]
        self.files_not_in_documentation.each do |file|
          s.rdoc_options        += [ '--exclude', file ]
        end

        s.files                 = self.files
        s.executables           = [ 'nanoc3' ]
        s.require_path          = 'lib'
        s.bindir                = 'bin'
      end
    end

  end

end
