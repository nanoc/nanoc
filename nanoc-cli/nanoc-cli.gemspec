# frozen_string_literal: true

require_relative 'lib/nanoc/cli/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-cli'
  s.version     = Nanoc::CLI::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'CLI for Nanoc'
  s.description = 'Provides the CLI for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency('nanoc-core', "= #{Nanoc::CLI::VERSION}")
  s.add_runtime_dependency('zeitwerk', '~> 2.1')
end
