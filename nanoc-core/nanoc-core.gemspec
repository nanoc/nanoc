# frozen_string_literal: true

require_relative 'lib/nanoc/core/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-core'
  s.version     = Nanoc::Core::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'Core of Nanoc'
  s.description = 'Contains the core of Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb'] + Dir['lib/**/*-schema.json']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency('concurrent-ruby', '~> 1.1')
  s.add_runtime_dependency('ddmemoize', '~> 1.0')
  s.add_runtime_dependency('ddmetrics', '~> 1.0')
  s.add_runtime_dependency('ddplugin', '~> 1.0')
  s.add_runtime_dependency('hamster', '~> 3.0')
  s.add_runtime_dependency('json_schema', '~> 0.19')
  s.add_runtime_dependency('slow_enumerator_tools', '~> 1.0')
  s.add_runtime_dependency('tty-platform', '~> 0.2')
  s.add_runtime_dependency('zeitwerk', '~> 2.1')
end
