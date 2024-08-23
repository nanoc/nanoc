# frozen_string_literal: true

require_relative 'lib/nanoc/live/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-live'
  s.version     = Nanoc::Live::VERSION
  s.homepage    = 'https://nanoc.app/'
  s.summary     = 'Live recompilation support for Nanoc'
  s.description = 'Provides support for auto-recompiling Nanoc sites.'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.1'

  s.add_dependency('adsf-live', '~> 1.4')
  s.add_dependency('listen', '~> 3.0')
  s.add_dependency('nanoc-cli', '~> 4.11', '>= 4.11.14')
  s.add_dependency('nanoc-core', '~> 4.11', '>= 4.11.14')
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.name}-v#{s.version}/#{s.name}",
  }
end
