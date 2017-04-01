usage 'nanoc command [options] [arguments]'
summary 'Nanoc, a static site compiler written in Ruby'
default_subcommand 'compile'

opt :l, :color, 'enable color' do
  $stdout.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :d, :debug, 'enable debugging' do
  Nanoc::CLI.debug = true
end

opt :e, :env, 'set environment', argument: :required do |value|
  ENV.store('NANOC_ENV', value)
end

opt :h, :help, 'show the help message and quit' do |_value, cmd|
  puts cmd.help
  exit 0
end

opt :C, :'no-color', 'disable color' do
  $stdout.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :V, :verbose, 'make output more detailed', multiple: true do |val|
  Nanoc::CLI::Logger.instance.level = :low
  Nanoc::CLI.verbosity = val.size
end

opt :v, :version, 'show version information and quit' do
  puts Nanoc.version_information
  exit 0
end

opt :w, :warn, 'enable warnings' do
  $-w = true
end
