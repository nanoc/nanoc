# This file is a large mess. It's basically the place where everything gets
# dumped if it doesn't belong elsewhere. Embarrassing, really.

# Get requirements
begin ; require 'rubygems' ; rescue LoadError ; end
require 'yaml'
require 'fileutils'

# Convenience function for printing warnings
def warn(s, pre='WARNING')
  $stderr.puts "#{pre}: #{s}" unless ENV['QUIET']
end

# Convenience function for cd'ing in and out of a directory
def in_dir(path)
  FileUtils.cd(File.join(path))
  yield
ensure
  FileUtils.cd(File.join(path.map { |n| '..' }))
end

############################# OLD AND DEPRECATED #############################

# Logging (level can be :off, :high, :low)
$log_level = :high
def log(log_level, s, io=$stdout)
  io.puts s if ($log_level == :low or $log_level == log_level) and $log_level != :off
end

# Convenience function for printing errors
def error(s, pre='ERROR')
  log(:high, pre + ': ' + s, $stderr)
  exit(1)
end

def nanoc_require(x)
  warn(
    "'nanoc_require' is deprecated and will be removed in a future version. Please use 'require' instead.",
    'DEPRECATION WARNING'
  )
  require x
end
