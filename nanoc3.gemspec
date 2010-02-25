# encoding: utf-8

require 'nanoc3'

Gem::Specification.new do |s|
  s.name     = 'nanoc3'
  s.version  = Nanoc3::VERSION
  s.summary  = 'a web publishing system written in Ruby for building small to medium-sized websites.'
  s.homepage = 'http://nanoc.stoneship.org/'

  s.authors = 'Denis Defreyne'
  s.email   = 'denis.defreyne@stoneship.org'

  s.files              = Dir['[A-Z]*'] + Dir['lib/**/*']
  s.default_executable = 'nanoc3'
  s.executables        = [ 'nanoc3' ]
  s.require_paths      = [ 'lib' ]

  s.has_rdoc         = 'yard'
  s.rdoc_options     = [ '--main', 'README.md' ]
  s.extra_rdoc_files = [ 'ChangeLog', 'LICENSE', 'README.md', 'NEWS.md' ]

  s.add_runtime_dependency('cri', '>= 1.0.0')

  s.post_install_message = %q{------------------------------------------------------------------------------
Thanks for installing nanoc 3.1! Here are some resources to help you get
started:

* The tutorial at <http://nanoc.stoneship.org/tutorial/>
* The manual at <http://nanoc.stoneship.org/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 3.1 has quite a few new features, be sure to check out the nanoc
blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
------------------------------------------------------------------------------
}
end
