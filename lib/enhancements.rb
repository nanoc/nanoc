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
    raise "ERROR: expected 1 #{a_noun}, found #{self.size} (#{a_context})" if self.size != 1
  end
end

class File
  # Reads the contents of the entire file
  def self.read_file(a_filename)
    content = ''
    File.open(a_filename) { |io| content = io.read }
    content
  end

  # Returns the contents of an entire file interpreted as YAML
  def self.read_yaml(a_filename)
    YAML::load(self.read_file(a_filename)) || {}
  end

  # Returns the contents of an entire file interpreted as YAML and cleaned
  def self.read_clean_yaml(a_filename)
    self.read_yaml(a_filename).clean
  end
end

class Hash
  # Converts all keys to symbols, and converts *_at and *_on
  # keys to Times and Dates, respectively
  def clean
    hash = {}

    self.each_pair do |key, value|
      if key =~ /_on$/
        hash[key.to_sym] = Date.parse(value)
      elsif key =~ /_at$/
        hash[key.to_sym] = Time.parse(value)
      elsif value == 'true'
        hash[key.to_sym] = true
      elsif value == 'false'
        hash[key.to_sym] = false
      else
        hash[key.to_sym] = value
      end
    end

    hash
  end
end

class String
  # Runs the string through the filters as given by the array of
  # filter names. Available filters include 'markdown', 'smartypants' and 'eruby'.
  def filter!(a_filters, a_params={})
    a_filters.each do |filter|
      case filter
      when 'markdown'
        self.replace(self.markdown)
      when 'smartypants'
        self.replace(self.smartypants)
      when 'eruby'
        self.replace(self.eruby(a_params[:eruby_context]))
      end
    end
  end

  # Converts the string to HTML using Markdown.
  def markdown
    BlueCloth::new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#markdown failed: BlueCloth not installed'
    exit
  end

  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def smartypants
    RubyPants::new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#smartypants failed: RubyPants not installed'
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
    unless File.directory?(File.join(@@stack))
      puts '     create ' + @@stack.join('/')
      FileUtils.mkdir_p(@@stack.join('/'))
    end
    yield if block_given?
    @@stack.pop
  end

  def self.create_file(a_name)
    path = @@stack.empty? ? a_name : @@stack.join('/') + '/' + a_name
    FileManager.create_dir(path.sub(/\/[^\/]+$/, '')) if @@stack.empty?
    puts "     #{File.exist?(a_name) ? 'update' : 'create'} " + path
    if block_given?
      open(path, 'w') { |io| io.write(yield) }
    else
      open(path, 'w') { |io| }
    end
  end

end
