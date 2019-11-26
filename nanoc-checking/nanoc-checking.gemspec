# frozen_string_literal: true

require_relative 'lib/nanoc/checking/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-checking'
  s.version     = Nanoc::Checking::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'Checking support for Nanoc'
  s.description = 'Provides checking functionality for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency('nanoc-cli', '~> 4.11', '>= 4.11.14')
  s.add_runtime_dependency('nanoc-core', '~> 4.11', '>= 4.11.14')
end
