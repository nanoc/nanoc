# Convenience function for printing warnings
def warn(s, pre='WARNING')
  $stderr.puts "#{pre}: #{s}" unless ENV['QUIET']
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
