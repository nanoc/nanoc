# encoding: utf-8

module Nanoc

  class Pattern

    def self.from(obj)
      case obj
      when Nanoc::StringPattern, Nanoc::RegexpPattern
        obj
      when String
        Nanoc::StringPattern.new(obj)
      when Regexp
        Nanoc::RegexpPattern.new(obj)
      else
        raise ArgumentError, "Do not know how to convert #{obj} into a Nanoc::Pattern"
      end
    end

    def initialize(obj)
      raise NotImplementedError
    end

    def match?(identifier)
      raise NotImplementedError
    end

  end

  class StringPattern

    def initialize(string)
      @string = string
    end

    def match?(identifier)
      # TODO allow matching /foo.{md,txt}
      File.fnmatch(@string, identifier.to_s, File::FNM_PATHNAME)
    end

  end

  class RegexpPattern

    def initialize(regexp)
      @regexp = regexp
    end

    def match?(identifier)
      identifier.to_s =~ @regexp
    end

  end

end
