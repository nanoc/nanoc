def try_require(s)
  require s
rescue LoadError
end

def nanoc_require(s)
  require s
rescue LoadError
  $stderr.puts "ERROR: You need '#{s}' to compile this site." unless $quiet
  exit
end

try_require 'rubygems'

require 'fileutils'

def handle_exception(exception, text)
  unless $quiet or exception.class == SystemExit
    $stderr.puts "ERROR: Exception occured while #{text}:\n"
    $stderr.puts exception
    $stderr.puts exception.backtrace.join("\n")
  end
  exit
end

class FileLogger
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

  attr_reader :out

  def initialize(a_out = $stdout)
    @out = a_out
  end

  def log(a_action, a_path)
    @out.puts('%s%12s%s  %s' % [ACTION_COLORS[a_action.to_sym], a_action, COLORS[:reset], a_path]) unless $quiet
  end

  private

  def method_missing(a_method, *a_args)
    log(a_method.to_s, a_args.first)
  end
end

class FileManager
  @@stack = []
  @@logger = FileLogger.new

  def self.create_dir(a_name)
    @@stack.pushing(a_name) do
      path = File.join(@@stack)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
        @@logger.create(path)
      end
      yield if block_given?
    end
  end

  def self.create_file(a_name)
    path = File.join(@@stack + [ a_name ])
    FileManager.create_dir(path.sub(/\/[^\/]+$/, '')) if @@stack.empty?
    content = block_given? ? yield : nil
    if File.exist?(path)
      if block_given? and File.read(path) == content
        @@logger.identical(path)
      else
        @@logger.update(path)
      end
    else
      @@logger.create(path)
    end
    open(path, 'w') { |io| io.write(content) unless content.nil? }
  end
end

def render(a_name, a_context={})
  assigns = a_context.merge({ :page => @page, :pages => @pages })
  File.read('layouts/' + a_name.to_s + '.erb').eruby(:assigns => assigns)
end
