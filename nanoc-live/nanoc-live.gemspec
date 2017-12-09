# frozen_string_literal: true

require_relative 'lib/nanoc/live/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-live'
  s.version     = Nanoc::Live::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'Live recompilation support for Nanoc'
  s.description = 'Provides support for auto-recompiling Nanoc sites.'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.has_rdoc = false

  s.required_ruby_version = '~> 2.3'

  s.add_runtime_dependency('adsf-live', '~> 1.4')
  s.add_runtime_dependency('listen', '~> 3.0')
  s.add_runtime_dependency('nanoc', '~> 4.8', '>= 4.8.16')
end
