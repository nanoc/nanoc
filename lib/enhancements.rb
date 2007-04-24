require 'erubis'
require 'time'
require 'yaml'

begin
  require 'bluecloth'
  require 'rubypants'
rescue
end

class Array
  # Ensures that the array contains only one element
  def ensure_single(a_params={})
    noun    = a_params[:noun]
    context = a_params[:context]

    if self.empty?
      puts 'ERROR: no ' + noun + ' found' + (context.nil? ? '' : " (#{context})")
      exit
    elsif self.size != 1
      puts 'ERROR: multiple ' + noun + ' found' + (context.nil? ? '' : " (#{context})")
      exit
    end
  end
end

class Date
  # Formats the date in a human-readable format
  def format_nicely
    "#{Date::MONTHNAMES[mon]} #{mday}, #{year}"
  end

  # Formats the date in the format required by Atom feeds
  def to_atom_date
    self.strftime("%Y-%m-%d")
  end
end

class File
  # Reads the contents of the entire file
  def self.read_file(a_filename)
    content = ''
    File.open(a_filename) do |io|
      io.each_line do |line|
        content += line
      end
    end
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

class Fixnum
  def to_mon_s
    Date::MONTHNAMES[self]
  end
  
  def to_abbr_mon_s
    Date::ABBR_MONTHNAMES[self]
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

class Numeric
  def ordinal
    if (10...20).include?(self) then
      self.to_s + 'th'
    else
      self.to_s + %w{th st nd rd th th th th th th}[self % 10]
    end
  end
end

class String
  # Runs the string through the filters as given by the array of
  # filter names. Available filters include 'markdown' and 'eruby'.
  def filter!(a_filters, a_params={})
    a_filters.each do |filter|
      case filter
      when 'markdown'
        self.markdown!
      when 'rubypants'
        self.rubypants!
      when 'eruby'
        self.eruby!(a_params[:eruby_context])
      end
    end
  end

  # Converts the string to HTML using Markdown.
  def markdown
    BlueCloth::new(self).to_html
  end

  # Converts the string to HTML using Markdown.
  def markdown!
    self.replace(self.markdown)
  end

  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def rubypants
    RubyPants::new(self).to_html
  end

  # Styles the string as HTML by converting quotes, dashes, ... using RubyPants
  def rubypants!
    self.replace(self.rubypants)
  end

  # Converts the string using eRuby.
  def eruby(a_context)
    Erubis::Eruby.new(self).evaluate(a_context)
  end

  # Converts the string using eRuby.
  def eruby!(a_context)
    self.replace(self.eruby(a_context))
  end
end

class Time
  # Formats the time in a human-readable format
  def format_nicely
    "#{Date::MONTHNAMES[mon]} #{mday}, #{year}"
  end

  # Formats the time as a date in the format required by Atom feeds
  def to_iso8601_date
    self.strftime("%Y-%m-%d")
  end
  alias to_atom_date to_iso8601_date

  # Formats the time in the format required by Atom feeds
  def to_iso8601_time
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
  alias to_atom_time to_iso8601_time
end

# Escapes the given string to make it harmless
def html_escape(a_string)
  a_string.gsub('&', '&amp;').gsub('<', '&lt;')
end
alias h html_escape
