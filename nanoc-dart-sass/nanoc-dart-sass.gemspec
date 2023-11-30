# frozen_string_literal: true

require_relative 'lib/nanoc/dart_sass/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-dart-sass'
  s.version     = Nanoc::DartSass::VERSION
  s.homepage    = 'https://nanoc.ws/'
  s.summary     = 'Dart Sass filter for Nanoc'
  s.description = 'Provides a :dart_sass filter for Nanoc'
  s.author      = 'Denis Defreyne'
  s.email       = 'denis+rubygems@denis.ws'
  s.license     = 'MIT'

  s.files         = ['NEWS.md', 'README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.7'

  s.add_runtime_dependency('nanoc-core', '~> 4.12')
  s.add_runtime_dependency('sass-embedded', '~> 1.56')
  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => "https://github.com/nanoc/nanoc/tree/#{s.name}-v#{s.version}/#{s.name}"
  }
end
