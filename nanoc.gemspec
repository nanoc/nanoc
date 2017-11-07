# frozen_string_literal: true

require_relative 'lib/nanoc/version'

ignored_files = %w[
  .github/CONTRIBUTING.md
  .github/ISSUE_TEMPLATE.md
  .github/PULL_REQUEST_TEMPLATE.md
  .gitignore
  .travis.yml
  scripts/release
  Gemfile
  Guardfile
]

gemspecs = Dir['nanoc-*.gemspec'].map { |fn| eval(File.read(fn), binding, fn) }
plugin_files = gemspecs.flat_map(&:files).uniq.reject { |fn| fn =~ /spec_helper_common/ }

Gem::Specification.new do |s|
  s.name        = 'nanoc'
  s.version     = Nanoc::VERSION
  s.homepage    = 'http://nanoc.ws/'
  s.summary     = 'A static-site generator with a focus on flexibility.'
  s.description = 'Nanoc is a static-site generator focused on flexibility. It transforms content from a format such as Markdown or AsciiDoc into another format, usually HTML, and lays out pages consistently to retain the site’s look and feel throughout. Static sites built with Nanoc can be deployed to any web server.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis@stoneship.org'
  s.license = 'MIT'

  all_files = `git ls-files -z`.split("\x0")
  s.files = all_files - plugin_files - ignored_files
  s.executables        = ['nanoc']
  s.require_paths      = ['lib']

  s.rdoc_options     = ['--main', 'README.md']
  s.extra_rdoc_files = ['LICENSE', 'README.md', 'NEWS.md']

  s.required_ruby_version = '>= 2.3.0'

  s.add_runtime_dependency('addressable', '~> 2.5')
  s.add_runtime_dependency('cri', '~> 2.8')
  s.add_runtime_dependency('ddplugin', '~> 1.0')
  s.add_runtime_dependency('hamster', '~> 3.0')
  s.add_runtime_dependency('ref', '~> 2.0')
  s.add_runtime_dependency('slow_enumerator_tools', '~> 1.0')

  s.add_development_dependency('appraisal', '~> 2.1')
end
