# encoding: utf-8

version = "4.0.0a1"

min_version_pattern = ">= #{version}"
max_version_pattern = "< #{version[0].to_i+1}.0.0"

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = version
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'a web publishing system written in Ruby for building small to medium-sized websites.'
  s.description = 'nanoc is a simple but very flexible static site generator written in Ruby. It operates on local files, and therefore does not run on the server. nanoc “compiles” the local source files into HTML (usually), by evaluating eRuby, Markdown, etc.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis.defreyne@stoneship.org'
  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.files              = Dir['[A-Z]*'] +
                         [ 'nanoc.gemspec' ]

  s.rdoc_options     = [ '--main', 'README.md' ]
  s.extra_rdoc_files = [ 'LICENSE', 'README.md', 'NEWS.md' ]

  s.add_runtime_dependency('nanoc-core', min_version_pattern, max_version_pattern)
  s.add_runtime_dependency('nanoc-cli',  min_version_pattern, max_version_pattern)
end
