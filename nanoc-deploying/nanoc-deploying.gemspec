# frozen_string_literal: true

require_relative 'lib/nanoc/deploying/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-deploying'
  s.version     = Nanoc::Deploying::VERSION
  s.homepage    = 'https://nanoc.app/'
  s.summary     = 'Deploying support for Nanoc'
  s.description = 'Provides deploying functionality for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.1'

  s.add_dependency('nanoc-checking', '~> 1.0')
  s.add_dependency('nanoc-cli', '~> 4.11', '>= 4.11.15')
  s.add_dependency('nanoc-core', '~> 4.11', '>= 4.11.15')
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.name}-v#{s.version}/#{s.name}",
  }
end
