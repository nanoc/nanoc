# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'nanoc/version'

Gem::Specification.new do |s|
  # Basic informations
  s.name          = 'nanoc'
  s.version       = Nanoc::VERSION
  s.homepage      = 'http://nanoc.ws/'
  s.summary       = 'a web publishing system written in Ruby for building small to medium-sized websites.'
  s.description   = 'nanoc is a simple but very flexible static site generator written in Ruby. It operates on local files, and therefore does not run on the server. nanoc “compiles” the local source files into HTML (usually), by evaluating eRuby, Markdown, etc.'

  # Author
  s.author        = 'Denis Defreyne'
  s.email         = 'denis.defreyne@stoneship.org'
  s.license       = 'MIT'

  # Files
  s.files = Dir[
    '[A-Z]*',
    'doc/yardoc_{templates,handlers}/**/*',
    '{bin,lib,tasks,test}/**/*',
    'nanoc.gemspec',
  ]

  # Directories
  s.executables = ['nanoc']
  s.require_paths = ['lib']

  # Documentation files
  s.rdoc_options = ['--main', 'README.md']
  s.extra_rdoc_files = ['ChangeLog', 'LICENSE', 'README.md', 'NEWS.md']

  # Ruby, dependencies
  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency('cri', '~> 2.3')

  s.add_development_dependency('bundler', '>= 1.7.10', '< 2.0')
end
