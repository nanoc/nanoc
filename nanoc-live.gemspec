# frozen_string_literal: true

require_relative 'lib/nanoc/version'
require_relative 'lib/nanoc/live/version'

Gem::Specification.new do |s|
  s.name        = 'nanoc-live'
  s.version     = Nanoc::Live::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'Live command for Nanoc'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis@stoneship.org'
  s.license = 'MIT'

  all_files = `git ls-files -z`.split("\x0")
  s.files         = all_files.select { |fn| fn =~ %r{nanoc[_/-]live|spec_helper_common} }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.3.0'

  s.add_runtime_dependency('listen', '~> 3.0')
  s.add_runtime_dependency('slow_enumerator_tools', '~> 1.0')
end
