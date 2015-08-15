module Nanoc::Int
  # @api private
  class Pattern
    def self.from(obj)
      case obj
      when Nanoc::Int::StringPattern, Nanoc::Int::RegexpPattern
        obj
      when String
        Nanoc::Int::StringPattern.new(obj)
      when Regexp
        Nanoc::Int::RegexpPattern.new(obj)
      else
        raise ArgumentError, "Do not know how to convert `#{obj.inspect}` into a Nanoc::Pattern"
      end
    end

    def initialize(_obj)
      raise NotImplementedError
    end

    def match?(_identifier)
      raise NotImplementedError
    end

    def captures(_identifier)
      raise NotImplementedError
    end
  end

  # @api private
  class StringPattern
    def initialize(string)
      @string = string
    end

    def match?(identifier)
      opts = File::FNM_PATHNAME | File::FNM_EXTGLOB
      File.fnmatch(@string, identifier.to_s, opts)
    end

    def captures(_identifier)
      nil
    end

    def to_s
      @string
    end
  end

  # @api private
  class RegexpPattern
    def initialize(regexp)
      @regexp = regexp
    end

    def match?(identifier)
      (identifier.to_s =~ @regexp) != nil
    end

    def captures(identifier)
      matches = @regexp.match(identifier.to_s)
      matches && matches.captures
    end

    def to_s
      @regexp.to_s
    end
  end
end
