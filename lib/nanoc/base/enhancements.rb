# Get requirements
begin ; require 'rubygems' ; rescue LoadError ; end
require 'yaml'
require 'fileutils'

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

# Convenience function for requiring libraries
def nanoc_require(x)
  require x
rescue LoadError
  error("This site requires #{x} to be built.")
end

# Convenience function for requiring autocompilation libraries
def nanoc_autocompile_require(x)
  require x
rescue LoadError
  error("The auto-compilation feature requires #{x} to be installed.")
end

# Rendering sub-layouts
def render(name, other_assigns={})
  layout = @site.layouts.find { |l| l[:name] == name }
  layout_processor_class = Nanoc::PluginManager.layout_processor_for_extension(layout[:extension])
  layout_processor = layout_processor_class.new(@page, @pages, @site.config, @site, other_assigns)
  layout_processor.run(layout[:content])
end

# Convenience function for cd'ing in and out of a directory
def in_dir(path)
  FileUtils.cd(File.join(path))
  yield
ensure
  FileUtils.cd(File.join(path.map { |n| '..' }))
end

class FileManager

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

    # Get content
    content = block_given? ? yield : nil
    modified = (File.exist?(path) and File.read(path) != content)

    # Log
    if File.exist?(path)
      file_log(*(modified ? [ :high, :update, path ] : [ :low, :identical, path ]))
    else
      file_log(:high, :create, path)
    end

    # Write
    open(path, 'w') { |io| io.write(content) unless content.nil? }

    # Report back
    modified
  end

end
