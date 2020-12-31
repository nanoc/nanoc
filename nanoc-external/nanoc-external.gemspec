# frozen_string_literal: true

require_relative 'lib/nanoc/external/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-external'
  s.version     = Nanoc::External::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'External filter for Nanoc'
  s.description = 'Provides an :external filter for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency('nanoc-core', '~> 4.11', '>= 4.11.14')
end
