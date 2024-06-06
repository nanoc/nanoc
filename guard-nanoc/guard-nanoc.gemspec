# frozen_string_literal: true

require_relative 'lib/guard/nanoc/version'

Gem::Specification.new do |s|
  s.name          = 'guard-nanoc'
  s.version       = Guard::GUARD_NANOC_VERSION
  s.homepage      = 'https://nanoc.app/'
  s.summary       = 'guard gem for Nanoc'
  s.description   = 'Automatically rebuilds Nanoc sites'
  s.license       = 'MIT'

  s.author        = 'Denis Defreyne'
  s.email         = 'denis.defreyne@stoneship.org'

  s.required_ruby_version = '>= 3.1'

  s.add_dependency 'guard', '~> 2.8'
  s.add_dependency 'guard-compat', '~> 1.0'
  s.add_dependency 'nanoc-cli', '~> 4.11', '>= 4.11.14'
  s.add_dependency 'nanoc-core', '~> 4.11', '>= 4.11.14'

  s.files         = Dir['[A-Z]*'] + Dir['lib/**/*'] + ['guard-nanoc.gemspec']
  s.require_paths = ['lib']
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.name}-v#{s.version}/#{s.name}",
  }
end
