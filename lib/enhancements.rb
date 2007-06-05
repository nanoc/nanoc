def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'
try_require 'bluecloth'
try_require 'rubypants'
try_require 'active_support'
require     'erubis'
require     'fileutils'
require     'yaml'

class Array
  # Ensures that the array contains only one element
  def ensure_single(a_noun, a_context)
    if self.size != 1
      $stderr.puts "ERROR: expected 1 #{a_noun}, found #{self.size} (#{a_context})" unless $quiet
      exit
    end
  end
end

module YAML
  # Returns the contents of an entire file interpreted as YAML and cleaned
  def self.load_file_and_clean(a_filename)
    (YAML.load_file(a_filename) || {}).clean
  end
end

class Hash
  # Converts all keys to symbols,
  # converts *_at and *_on to Times and Dates, respectively,
  # converts 'true' and 'false' strings to booleans,
  # converts 'none' to nil
  def clean
    inject({}) do |hash, (key, value)|
      if key =~ /_on$/
        hash[key.to_sym] = Date.parse(value)
      elsif key =~ /_at$/
        hash[key.to_sym] = Time.parse(value)
      elsif value == 'true'
        hash[key.to_sym] = true
      elsif value == 'false'
        hash[key.to_sym] = false
      elsif value == 'none'
        hash[key.to_sym] = nil
      else
        hash[key.to_sym] = value
      end
      hash
    end
  end
end

class String
  # Runs the string through the filters as given by the array of
  # filter names. Available filters include 'markdown', 'smartypants' and 'eruby'.
  def filter(a_filters, a_params={})
    a_filters.inject(self) do |result, filter|
      case filter
      when 'markdown'
        result.replace(result.markdown)
      when 'smartypants'
        result.replace(result.smartypants)
      when 'eruby'
        result.replace(result.eruby(a_params[:eruby_context]))
      end
    end
  end

  # Converts the string to HTML using Markdown.
  def markdown
    BlueCloth::new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#markdown failed: BlueCloth not installed' unless $quiet
    exit
  end

  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def smartypants
    RubyPants::new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#smartypants failed: RubyPants not installed' unless $quiet
    exit
  end

  # Converts the string using eRuby.
  def eruby(a_context={})
    Erubis::Eruby.new(self).evaluate(a_context)
  end
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

  # Creates a new directory with the given name
  def self.create_dir(a_name)
    @@stack.push(a_name)
    path = File.join(@@stack)
    unless File.directory?(path)
      FileUtils.mkdir_p(path) unless $pretend
      system('svn', 'add', path) if $use_svn and !$pretend
      @@logger.create(path)
    end
    yield if block_given?
    @@stack.pop
  end

  # Creates a new file with the given name
  def self.create_file(a_name)
    path = File.join(@@stack + [ a_name ])
    FileManager.create_dir(path.sub(/\/[^\/]+$/, '')) if @@stack.empty? and !$pretend
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
    open(path, 'w') { |io| io.write(content) unless content.nil? } unless $pretend
    system('svn', 'add', path) if $use_svn and !$pretend
  end

  # Renames the given file
  def self.rename_file(a_old_name, a_new_name)
    old_path = File.join(@@stack + [ a_old_name ])
    new_path = File.join(@@stack + [ a_new_name ])
    return if old_path == new_path
    if File.exist?(new_path)
      $stderr.puts 'ERROR: File ' + old_path + ' already exists.'
      return
    end
    if $use_svn
      system('svn', 'mv', old_path, new_path) unless $pretend
    else
      FileUtils.mv(old_path, new_path, :force => true) unless $pretend
    end
    @@logger.move(old_path + "\n              => " + new_path)
  end
end

def render(a_name, a_context={})
  File.read('layouts/' + a_name + '.erb').eruby(a_context.merge({ :page => @page, :pages => @pages }))
end
