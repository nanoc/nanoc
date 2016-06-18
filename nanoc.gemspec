require_relative 'lib/nanoc/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = Nanoc::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'A static-site generator with a focus on flexibility.'
  s.description = 'Nanoc is a static-site generator focused on flexibility. It transforms content from a format such as Markdown or AsciiDoc into another format, usually HTML, and lays out pages consistently to retain the site’s look and feel throughout. Static sites built with Nanoc can be deployed to any web server.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis.defreyne@stoneship.org'
  s.license = 'MIT'

  s.files =
    Dir['[A-Z]*'] +
    Dir['doc/yardoc_{templates,handlers}/**/*'] +
    Dir['{bin,lib,tasks,test}/**/*'] +
    ['nanoc.gemspec']
  s.executables        = ['nanoc']
  s.require_paths      = ['lib']

  s.rdoc_options     = ['--main', 'README.md']
  s.extra_rdoc_files = ['ChangeLog', 'LICENSE', 'README.md', 'NEWS.md']

  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency('cri', '~> 2.3')
  s.add_runtime_dependency('contracts', '~> 0.14')

  s.add_development_dependency('bundler', '>= 1.7.10', '< 2.0')
end
