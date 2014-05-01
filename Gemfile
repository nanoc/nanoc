source "https://rubygems.org"

gemspec

# FIXME we may be missing some mswin dependencies here
all_rubies = Bundler::Dependency::PLATFORM_MAP.keys
ruby_19_plus               = [:ruby_19, :ruby_20, :ruby_21, :jruby] & all_rubies
ruby_19_plus_without_jruby = [:ruby_19, :ruby_20, :ruby_21]         & all_rubies

gem 'adsf'
gem 'bluecloth', :platforms => :ruby
gem 'builder'
gem 'coderay'
gem 'compass'
gem 'coffee-script'
gem 'coveralls', :require => false
gem 'erubis'
gem 'fog', :platforms => ruby_19_plus
gem 'haml'
gem 'handlebars', :platforms => ruby_19_plus_without_jruby
gem 'kramdown'
gem 'less', '~> 2.0', :platforms => :ruby
gem 'listen', :platforms => ruby_19_plus
gem 'markaby'
gem 'maruku'
gem 'mime-types', :platforms => ruby_19_plus
gem 'minitest', '~> 4.0'
gem 'mocha'
gem 'mustache'
gem 'nokogiri', '~> 1.6'
gem 'pandoc-ruby'
gem 'pry'
gem 'pygments.rb', :platforms => [:ruby, :mswin]
gem 'rack'
gem 'rake'
gem 'rainpress'
gem 'rdiscount', :platforms => [:ruby, :mswin]
gem 'rdoc'
gem 'redcarpet', :platforms => ruby_19_plus_without_jruby + [:mswin]
gem 'RedCloth'
gem 'rouge'
gem 'rubocop', :platforms => ruby_19_plus
gem 'rubypants'
gem 'sass', '~> 3.2.2'
gem 'slim'
gem 'typogruby'
gem 'uglifier'
gem 'vcr'
gem 'w3c_validators'
gem 'webmock'
gem 'yuicompressor', :platforms => ruby_19_plus
gem 'yard'
