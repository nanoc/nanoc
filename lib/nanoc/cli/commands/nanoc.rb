# encoding: utf-8

usage   'nanoc command [options] [arguments]'
summary 'nanoc, a static site compiler written in Ruby'

opt :l, :color, 'enable color' do
  $stdout.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :d, :debug, 'enable debugging' do
  Nanoc::CLI.debug = true
end

opt :h, :help, 'show the help message and quit' do |value, cmd|
  puts cmd.help
  exit 0
end

opt :C, :'no-color', 'disable color' do
  $stdout.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :V, :verbose, 'make nanoc output more detailed' do
  Nanoc::CLI::Logger.instance.level = :low
end

opt :v, :version, 'show version information and quit' do
  puts Nanoc.version_information
  exit 0
end

opt :w, :warn, 'enable warnings' do
  $-w = true
end

run do |opts, args, cmd|
  cmd.command_named('compile').run([])
end
