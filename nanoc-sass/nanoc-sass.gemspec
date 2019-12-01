# frozen_string_literal: true

require_relative 'lib/nanoc/sass/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-sass'
  s.version     = Nanoc::Sass::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'Sass support for Nanoc'
  s.description = 'Provides Sass functionality for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency('nanoc-core', '~> 4.11', '>= 4.11.14')
end
