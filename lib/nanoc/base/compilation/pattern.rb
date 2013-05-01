# encoding: utf-8

module Nanoc

  class Pattern

    def self.from(obj)
      klass = case obj
      when String
        Nanoc::StringPattern
      when Regexp
        Nanoc::RegexpPattern
      end
      klass.new(obj)
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
      File.fnmatch(@string, identifier.to_s)
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
