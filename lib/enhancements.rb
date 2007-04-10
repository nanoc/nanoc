class Date
  def format_nicely
    "#{Date::MONTHNAMES[mon]} #{mday}, #{year}"
  end
  
  def to_atom_date
    self.strftime("%Y-%m-%d")
  end
end

class File
  def self.read_file(a_filename)
    content = ''
    File.open(a_filename) do |io|
      io.each_line do |line|
        content += line
      end
    end
    content
  end
  
  def self.read_yaml(a_filename)
    YAML::load(self.read_file(a_filename))
  end
end

class Hash
  def clean
    hash = {}
    
    self.each_pair do |key, value|
      # Convert all keys to symbols
      hash[key.to_sym] = value
      
      # Convert *_on and *_at to Dates and Times
      if key =~ /_on$/
        hash[key.to_sym] = Date.parse(value)
      elsif key =~ /_at$/
        hash[key.to_sym] = Time.parse(value)
      end
    end
    
    hash
  end
end

class NilClass
  def true?
    false
  end
  
  def false?
    true
  end
end

class String
  def filter!(a_filters, a_context)
    a_filters.each do |filter|
      case filter
      when 'markdown'
        self.markdown!
      when 'eruby'
        self.eruby!(a_context)
      end
    end
  end
  
  def markdown
    BlueCloth::new(self).to_html
  end
  
  def markdown!
    self.replace(self.markdown)
  end
  
  def eruby(a_context)
    Erubis::Eruby.new(self).evaluate(a_context)
  end
  
  def eruby!(a_context)
    self.replace(self.eruby(a_context))
  end
end

class Time
  def format_nicely
    "#{Date::MONTHNAMES[mon]} #{mday}, #{year}"
  end
  
  def to_atom_date
    self.strftime("%Y-%m-%d")
  end
  
  def to_atom_time
    self.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end

def html_escape(a_string)
  a_string.gsub('&', '&amp;').gsub('<', '&lt;')
end
alias h html_escape
