# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: 'nanoc'
gemspec path: 'nanoc-core'
gemspec path: 'nanoc-cli'
gemspec path: 'nanoc-checking'
gemspec path: 'nanoc-dart-sass'
gemspec path: 'nanoc-deploying'
gemspec path: 'nanoc-external'
gemspec path: 'nanoc-org-mode'
gemspec path: 'nanoc-live'
gemspec path: 'nanoc-spec'
gemspec path: 'nanoc-tilt'
gemspec path: 'guard-nanoc'

group :release do
  gem 'netrc', '~> 0.11.0'
  gem 'octokit', '~> 9.2'
end

group :devel do
  gem 'addressable', '~> 2.8'
  gem 'contracts', '~> 0.16'
  gem 'debug', '~> 1.9'
  gem 'fuubar'
  gem 'guard-rake'
  gem 'json', '~> 2.1'
  gem 'm', '~> 1.5'
  gem 'minitest', '~> 5.11'
  gem 'mocha'
  gem 'pry'
  gem 'rake'
  gem 'rdoc', '~> 6.0'
  gem 'rspec'
  gem 'rspec-its', '~> 1.2'
  gem 'rspec-mocks'
  gem 'rubocop', '~> 1.31'
  gem 'rubocop-minitest'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'simplecov', '~> 0.22.0'
  gem 'timecop'
  gem 'tty-command', '~> 0.8'
  gem 'vcr'
  gem 'webmock'
  gem 'webrick', '~> 1.7'
  gem 'yard'
  gem 'yard-contracts'
end

group :plugins do
  gem 'adsf'
  gem 'adsf-live'
  gem 'asciidoctor'
  gem 'bluecloth', platforms: :ruby
  gem 'builder'
  gem 'clonefile', '~> 0.5.2'
  gem 'coderay'
  gem 'coffee-script'
  gem 'erubi'
  gem 'erubis'
  gem 'execjs', '~> 2.7'
  gem 'fog-aws'
  gem 'fog-local', '~> 0.6'
  gem 'haml', '~> 6.0'
  gem 'kramdown'
  gem 'less', '~> 2.6', platforms: :ruby
  gem 'listen', '~> 3.1'
  gem 'markaby'
  gem 'maruku'
  gem 'mime-types'
  gem 'mini_racer'
  gem 'mustache', '~> 1.0'
  gem 'nokogiri', '~> 1.12'
  gem 'pandoc-ruby'
  gem 'pygments.rb', '~> 2.0', platforms: :ruby
  gem 'rack'
  gem 'rainpress'
  gem 'redcarpet', '~> 3.4', platforms: :ruby
  gem 'RedCloth', platforms: :ruby
  gem 'rouge', '~> 4.1'
  gem 'ruby-handlebars'
  gem 'rubypants'
  gem 'sass'
  gem 'slim', '~> 5.0'
  gem 'terser'
  gem 'typogruby'
  gem 'w3c_validators'
  gem 'wdm', '>= 0.1.0' if Gem.win_platform?
  gem 'yuicompressor'

  # TODO: remove
  # See https://github.com/davidfstr/rdiscount/issues/155
  unless `clang --version`.match?(/clang version 16/)
    gem 'rdiscount', '~> 2.2', platforms: :ruby
  end
end
