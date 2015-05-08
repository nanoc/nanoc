# encoding: utf-8

module Nanoc
  class Identifier
    def initialize(string)
      @string = "/#{string}/".gsub(/^\/+|\/+$/, '/').freeze
    end

    def ==(other)
      to_s == other.to_s
    end

    def =~(pat)
      to_s =~ pat
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    def to_s
      @string
    end
  end
end
