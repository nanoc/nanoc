# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'nanoc'

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = Nanoc::VERSION
  s.homepage    = 'http://nanoc.stoneship.org/'
  s.summary     = 'a web publishing system written in Ruby for building small to medium-sized websites.'
  s.description = 'nanoc is a simple but very flexible static site generator written in Ruby. It operates on local files, and therefore does not run on the server. nanoc “compiles” the local source files into HTML (usually), by evaluating eRuby, Markdown, etc.'

  s.author = 'Denis Defreyne'
  s.email  = 'denis.defreyne@stoneship.org'

  s.files              = Dir['[A-Z]*'] +
                         Dir['doc/yardoc_templates/**/*'] +
                         Dir['{bin,lib,tasks,test}/**/*'] +
                         [ 'nanoc.gemspec', '.gemtest' ]
  s.executables        = [ 'nanoc' ]
  s.require_paths      = [ 'lib' ]

  s.rdoc_options     = [ '--main', 'README.md' ]
  s.extra_rdoc_files = [ 'ChangeLog', 'LICENSE', 'README.md', 'NEWS.md' ]

  s.add_runtime_dependency('cri', '~> 2.0')

  s.post_install_message = %q{------------------------------------------------------------------------------
Thanks for installing nanoc 3.2! Here are some resources to help you get
started:

* The web site at <http://nanoc.stoneship.org/>
* The tutorial at <http://nanoc.stoneship.org/docs/3-getting-started/>
* The manual at <http://nanoc.stoneship.org/docs/4-basic-concepts/>

If you have questions, issues or simply want to share ideas, join the
discussion at <http://groups.google.com/group/nanoc> or stop by in the IRC
channel on irc.freenode.net, channel #nanoc. See you there!

Enjoy!
------------------------------------------------------------------------------
}
end
