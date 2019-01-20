# frozen_string_literal: true

require_relative 'lib/nanoc/core/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-core'
  s.version     = Nanoc::Core::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'Core of Nanoc'
  s.description = 'Contains the core of Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb'] + Dir['lib/**/*-schema.json']
  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency('json_schema', '~> 0.19')
end
