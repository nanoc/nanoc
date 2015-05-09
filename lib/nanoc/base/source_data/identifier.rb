# encoding: utf-8

module Nanoc
  class Identifier
    include Comparable

    def initialize(string)
      @string = "/#{string}/".gsub(/^\/+|\/+$/, '/').freeze
    end

    def ==(other)
      to_s == other.to_s
    end
    alias_method :eql?, :==

    def hash
      self.class.hash ^ to_s.hash
    end

    def =~(pat)
      to_s =~ pat
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # @return [String]
    def chop
      to_s.chop
    end

    # @return [String]
    def +(string)
      to_s + string
    end

    def to_s
      @string
    end

    def to_str
      @string
    end

    def inspect
      "<Nanoc::Identifier #{to_s.inspect}>"
    end
  end
end
