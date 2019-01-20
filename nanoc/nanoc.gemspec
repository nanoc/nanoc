# frozen_string_literal: true

require_relative 'lib/nanoc/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = Nanoc::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'A static-site generator with a focus on flexibility.'
  s.description = 'Nanoc is a static-site generator focused on flexibility. It transforms content from a format such as Markdown or AsciiDoc into another format, usually HTML, and lays out pages consistently to retain the site’s look and feel throughout. Static sites built with Nanoc can be deployed to any web server.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis+rubygems@denis.ws'
  s.license = 'MIT'

  s.files = Dir['*.md'] + ['LICENSE'] + Dir['bin/*'] + Dir['lib/**/*.rb']
  s.executables        = ['nanoc']
  s.require_paths      = ['lib']

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency('addressable', '~> 2.5')
  s.add_runtime_dependency('cri', '~> 2.15')
  s.add_runtime_dependency('ddmemoize', '~> 1.0')
  s.add_runtime_dependency('ddmetrics', '~> 1.0')
  s.add_runtime_dependency('ddplugin', '~> 1.0')
  s.add_runtime_dependency('hamster', '~> 3.0')
  s.add_runtime_dependency('nanoc-core', "= #{Nanoc::VERSION}")
  s.add_runtime_dependency('parallel', '~> 1.12')
  s.add_runtime_dependency('ref', '~> 2.0')
  s.add_runtime_dependency('slow_enumerator_tools', '~> 1.0')
  s.add_runtime_dependency('tomlrb', '~> 1.2')
end
