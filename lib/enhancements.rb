class Date
  def format_nicely
    "#{Date::MONTHNAMES[mon]} #{mday}, #{year}"
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
    end
    hash
  end
  
  def clean!
    self.replace(self.clean)
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
