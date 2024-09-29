# frozen_string_literal: true

require_relative 'lib/nanoc/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = Nanoc::VERSION
  s.homepage    = 'https://nanoc.app/'
  s.summary     = 'A static-site generator with a focus on flexibility.'
  s.description = 'Nanoc is a static-site generator focused on flexibility. It transforms content from a format such as Markdown or AsciiDoc into another format, usually HTML, and lays out pages consistently to retain the site’s look and feel throughout. Static sites built with Nanoc can be deployed to any web server.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis+rubygems@denis.ws'
  s.license = 'MIT'

  s.files = Dir['*.md'] + ['LICENSE'] + Dir['bin/*'] + Dir['lib/**/*.rb']
  s.executables        = ['nanoc']
  s.require_paths      = ['lib']

  s.required_ruby_version = '>= 3.1'

  s.add_dependency('addressable', '~> 2.5')
  s.add_dependency('colored', '~> 1.2')
  s.add_dependency('nanoc-checking', '~> 1.0', '>= 1.0.2')
  s.add_dependency('nanoc-cli', "= #{Nanoc::VERSION}")
  s.add_dependency('nanoc-core', "= #{Nanoc::VERSION}")
  s.add_dependency('nanoc-deploying', '~> 1.0')
  s.add_dependency('parallel', '~> 1.12')
  s.add_dependency('tty-command', '~> 0.8')
  s.add_dependency('tty-which', '~> 0.4')
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.version}/#{s.name}",
  }
end
