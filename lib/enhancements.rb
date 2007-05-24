def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'
try_require 'bluecloth'
try_require 'rubypants'

require 'erubis'
require 'fileutils'
require 'yaml'

class Array
  # Ensures that the array contains only one element
  def ensure_single(a_noun, a_context)
    if self.size != 1
      $stderr.puts "ERROR: expected 1 #{a_noun}, found #{self.size} (#{a_context})" unless $quiet == true
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
  # Converts all keys to symbols, and converts *_at and *_on
  # keys to Times and Dates, respectively
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
    $stderr.puts 'ERROR: String#markdown failed: BlueCloth not installed' unless $quiet == true
    exit
  end

  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def smartypants
    RubyPants::new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#smartypants failed: RubyPants not installed' unless $quiet == true
    exit
  end

  # Converts the string using eRuby.
  def eruby(a_context={})
    Erubis::Eruby.new(self).evaluate(a_context)
  end
end

class FileManager
  @@stack = []

  def self.create_dir(a_name)
    @@stack.push(a_name)
    path = File.join(@@stack)
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
      log('create', path)
    end
    yield if block_given?
    @@stack.pop
  end

  def self.create_file(a_name)
    path = File.join(@@stack + [ a_name ])
    FileManager.create_dir(path.sub(/\/[^\/]+$/, '')) if @@stack.empty?
    content = block_given? ? yield : nil
    File.exist?(path) ? ( block_given? and File.read(path) == content ? log('identical', path) : log('update', path) ) : log('create', path)
    open(path, 'w') { |io| io.write(content) unless content.nil? }
  end
end

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
  :identical  => COLORS[:bold]
}

def log(a_action, a_path)
  puts format('%s%12s%s %s', ACTION_COLORS[a_action.to_sym], a_action, COLORS[:reset], a_path) unless $quiet == true
end

def render(a_name, a_context={})
  File.read('layouts/' + a_name + '.erb').eruby(a_context.merge({ :page => @page, :pages => @pages }))
end
