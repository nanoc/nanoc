# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Pattern
    include Nanoc::Int::ContractsSupport

    contract C::Any => self
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
  class StringPattern < Pattern
    MATCH_OPTS = File::FNM_PATHNAME | File::FNM_EXTGLOB

    contract String => C::Any
    def initialize(string)
      @string = string
    end

    contract C::Or[Nanoc::Identifier, String] => C::Bool
    def match?(identifier)
      File.fnmatch(@string, identifier.to_s, MATCH_OPTS)
    end

    contract C::Or[Nanoc::Identifier, String] => nil
    def captures(_identifier)
      nil
    end

    contract C::None => String
    def to_s
      @string
    end
  end

  # @api private
  class RegexpPattern < Pattern
    contract Regexp => C::Any
    def initialize(regexp)
      @regexp = regexp
    end

    contract C::Or[Nanoc::Identifier, String] => C::Bool
    def match?(identifier)
      (identifier.to_s =~ @regexp) != nil
    end

    contract C::Or[Nanoc::Identifier, String] => C::Maybe[C::ArrayOf[String]]
    def captures(identifier)
      matches = @regexp.match(identifier.to_s)
      matches && matches.captures
    end

    contract C::None => String
    def to_s
      @regexp.to_s
    end
  end
end
