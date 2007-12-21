# Get requirements
begin ; require 'rubygems' ; rescue LoadError ; end
require 'yaml'
require 'fileutils'

# Don't start out quiet
$quiet = false

# Convenience function for printing errors
def error(s, pre='ERROR')
  $stderr.puts pre + ': ' + s unless $quiet
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

def in_dir(path)
  FileUtils.cd(File.join(path))
  yield
ensure
  FileUtils.cd(File.join(path.map { |n| '..' }))
end

class FileManager

  COLORS = {
    :reset   => "\e[0m",

    :bold    => "\e[1m",

    :black   => "\e[30m",
    :red     => "\e[31m",
    :green   => "\e[32m",
    :yellow  => "\e[33m",
    :blue    => "\e[34m",
    :magenta => "\e[35m",
    :cyan    => "\e[36m",
    :white   => "\e[37m"
  }

  ACTION_COLORS = {
    :create     => COLORS[:bold] + COLORS[:green],
    :update     => COLORS[:bold] + COLORS[:yellow],
    :move       => COLORS[:bold] + COLORS[:blue],
    :identical  => COLORS[:bold]
  }

  def self.log(action, path)
    puts('%s%12s%s  %s' % [ACTION_COLORS[action.to_sym], action, COLORS[:reset], path]) unless $quiet
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
    content_changed = (File.exist?(path) and File.read(path) != content)

    # Log
    if File.exist?(path)
      log(content_changed ? :update : :identical, path)
    else
      log(:create, path)
    end

    # Write
    open(path, 'w') { |io| io.write(content) unless content.nil? }
  end

end
