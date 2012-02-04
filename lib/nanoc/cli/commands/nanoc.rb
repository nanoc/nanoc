# encoding: utf-8

usage   'nanoc command [options] [arguments]'
summary 'nanoc, a static site compiler written in Ruby'

opt :l, :color, 'enable color' do
  Nanoc::CLI::Logger.instance.color = true
end

opt :d, :debug, 'enable debugging' do
  Nanoc::CLI.debug = true
end

opt :h, :help, 'show the help message and quit' do |value, cmd|
  puts cmd.help
  exit 0
end

opt :C, :'no-color', 'disable color' do
  Nanoc::CLI::Logger.instance.color = false
end

opt :V, :verbose, 'make nanoc output more detailed' do
  Nanoc::CLI::Logger.instance.level = :low
end

opt :v, :version, 'show version information and quit' do
  gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"
  engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  puts "nanoc #{Nanoc::VERSION} © 2007-2012 Denis Defreyne.".make_compatible_with_env
  puts "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}"
  exit 0
end

opt :w, :warn, 'enable warnings' do
  $-w = true
end

run do |opts, args, cmd|
  cmd.command_named('compile').run([])
end
