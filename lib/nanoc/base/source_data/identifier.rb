# encoding: utf-8

module Nanoc

  class Identifier

    attr_reader :components

    def self.from_string(string)
      components = string.split('/').reject { |c| c.empty? }
      self.new(components)
    end

    def initialize(components)
      @components = components

      @components.freeze
      @components.each { |c| c.freeze }
    end

    def parent
      if self.components.empty?
        nil
      else
        parent_components = self.components[0..-2]
        self.class.new(parent_components)
      end
    end

    # FIXME ugly
    def prefix(prefix)
      self.class.from_string(prefix + self.to_s)
    end

    def extension
      s = self.to_s
      s[s.rindex('.')..-1]
    end

    def with_ext(ext)
      self.without_ext + '.' + ext
    end

    def without_ext
      self.to_s.sub(/\.\w+$/, '')
    end

    def hash
      self.components.hash
    end

    def eql?(other)
      self.to_s == other.to_s
    end

    def ==(other)
      self.eql?(other)
    end

    def <=>(other)
      self.to_s <=> other.to_s
    end

    def inspect
      "<#{self.class} #{self.to_s.inspect}>"
    end

    def to_s
      if self.components.empty?
        '/'
      else
        '/' + self.components.join('/')
      end
    end

  end

end
