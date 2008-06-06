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

# Rendering nested layouts
def render(name_or_path, other_assigns={})
  # Find layout
  layout = @site.layouts.find { |l| l.path == name_or_path.cleaned_path }
  raise Nanoc::Errors::UnknownLayoutError.new(name_or_path.cleaned_path) if layout.nil?

  # Find filter
  filter_class = layout.filter_class
  raise Nanoc::Errors::CannotDetermineFilterError.new(layout.path) if filter_class.nil?
  filter = filter_class.new(@page_rep, @page, @site, other_assigns)

  # Layout
  filter.run(layout.content)
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

class FileManager # :nodoc:

  ACTION_COLORS = {
    :create     => "\e[1m" + "\e[32m", # bold + green
    :update     => "\e[1m" + "\e[33m", # bold + yellow
    :identical  => "\e[1m"             # bold
  }

  def self.file_log(log_level, action, path)
    log(log_level, '%s%12s%s  %s' % [ACTION_COLORS[action.to_sym], action, "\e[0m", path])
  end

  def self.create_dir(name)
    # Check whether directory exists
    return if File.exist?(name)

    # Create dir
    FileUtils.mkdir_p(name)
    log(:create, name)
  end

  def self.create_file(path)
    # Create parent directory if necessary
    if path =~ /\//
      parent_path = path.sub(/\/[^\/]+$/, '')
      FileManager.create_dir(parent_path)
    end

    # Get contents
    content_old = File.exist?(path) ? File.read(path) : nil
    content_new = yield
    content_new = content_new.force_encoding(content_old.encoding) if content_old and String.method_defined?(:force_encoding)
    modified = (content_old != content_new)

    # Log
    if File.exist?(path)
      file_log(*(modified ? [ :high, :update, path ] : [ :low, :identical, path ]))
    else
      file_log(:high, :create, path)
    end

    # Write
    open(path, 'w') { |io| io.write(content_new) }

    # Report back
    modified
  end

end
