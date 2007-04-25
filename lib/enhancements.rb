def try ; yield rescue nil ; end

try { require 'rubygems' }
try { require 'bluecloth' }
try { require 'rubypants' }

require 'erubis'

class Array
  # Ensures that the array contains only one element
  def ensure_single(a_noun, a_context)
    if self.size != 1
      puts "ERROR: expected 1 #{a_noun}, found #{self.size} (#{a_context})"
      exit
    end
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
      else
        hash[key.to_sym] = value
      end
    end

    hash
  end
end

class String
  # Runs the string through the filters as given by the array of
  # filter names. Available filters include 'markdown', 'rubypants' and 'eruby'.
  def filter!(a_filters, a_params={})
    a_filters.each do |filter|
      case filter
      when 'markdown'
        self.replace(self.markdown)
      when 'rubypants'
        self.replace(self.rubypants)
      when 'eruby'
        self.replace(self.eruby(a_params[:eruby_context]))
      end
    end
  end

  # Converts the string to HTML using Markdown.
  def markdown
    BlueCloth::new(self).to_html
  end
  
  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def rubypants
    RubyPants::new(self).to_html
  end

  # Converts the string using eRuby.
  def eruby(a_context)
    Erubis::Eruby.new(self).evaluate(a_context)
  end
end
