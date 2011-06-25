# encoding: utf-8

usage   'nanoc command [options] [arguments]'
summary 'nanoc, a static site compiler written in Ruby'

opt :l, :color, 'enable color' do
  Nanoc3::CLI::Logger.instance.color = true
end

opt :d, :debug, 'enable debugging' do
  Nanoc3::CLI.debug = true
end

opt :h, :help, 'show the help message and quit' do |value, cmd|
  puts cmd.help
  exit 0
end

opt :C, :'no-color', 'disable color' do
  Nanoc3::CLI::Logger.instance.color = false
end

opt :V, :verbose, 'make nanoc output more detailed' do
  Nanoc3::CLI::Logger.instance.level = :low
end

opt :v, :version, 'show version information and quit' do
  gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"
  engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  puts "nanoc #{Nanoc3::VERSION} (c) 2007-2011 Denis Defreyne."
  puts "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}"
  exit 0
end

opt :w, :warn, 'enable warnings' do
  $-w = true
end
