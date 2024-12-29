# frozen_string_literal: true

require_relative 'lib/nanoc/cli/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-cli'
  s.version     = Nanoc::CLI::VERSION
  s.homepage    = 'https://nanoc.app/'
  s.summary     = 'CLI for Nanoc'
  s.description = 'Provides the CLI for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.1'

  s.add_dependency('cri', '~> 2.15')
  s.add_dependency('diff-lcs', '~> 1.3')
  s.add_dependency('logger', '~> 1.6')
  s.add_dependency('nanoc-core', "= #{Nanoc::CLI::VERSION}")
  s.add_dependency('pry', '>= 0')
  s.add_dependency('zeitwerk', '~> 2.1')
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.name}-v#{s.version}/#{s.name}",
  }
end
