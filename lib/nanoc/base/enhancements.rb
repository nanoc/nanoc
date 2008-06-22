# Convenience function for printing warnings
def warn(s, pre='WARNING')
  $stderr.puts "#{pre}: #{s}" unless ENV['QUIET']
end

############################# OLD AND DEPRECATED #############################

def nanoc_require(x)
  warn(
    "'nanoc_require' is deprecated and will be removed in a future version. Please use 'require' instead.",
    'DEPRECATION WARNING'
  )
  require x
end
