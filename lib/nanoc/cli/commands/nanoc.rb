usage 'nanoc command [options] [arguments]'
summary 'Nanoc, a static site compiler written in Ruby'

opt :l, :color, 'enable color' do
  $stdout.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.remove_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :d, :debug, 'enable debugging' do
  Nanoc::CLI.debug = true
end

if Nanoc::Feature.enabled?(Nanoc::Feature::ENVIRONMENTS)
  opt :e, :env, 'set environment', argument: :required do |value|
    ENV.store('NANOC_ENV', value)
  end
end

opt :h, :help, 'show the help message and quit' do |_value, cmd|
  puts cmd.help
  exit 0
end

opt :C, :'no-color', 'disable color' do
  $stdout.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
  $stderr.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
end

opt :V, :verbose, 'make output more detailed' do
  Nanoc::CLI::Logger.instance.level = :low
end

opt :v, :version, 'show version information and quit' do
  puts Nanoc.version_information
  exit 0
end

opt :w, :warn, 'enable warnings' do
  $-w = true
end

run do |_opts, _args, cmd|
  cmd.command_named('compile').run([])
end
