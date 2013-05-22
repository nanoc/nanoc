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

    def match?(pattern)
      File.fnmatch(pattern, self.to_s)
    end

    # FIXME ugly
    def prefix(prefix)
      self.class.from_string(prefix + self.to_s)
    end

    def add_component(string)
      self.class.new(self.components + [ string ])
    end

    def extension
      c = self.components[-1]
      idx = c.rindex('.')
      if idx
        c[idx+1..-1]
      else
        nil
      end
    end

    def with_ext(ext)
      cs = self.without_ext.components.dup
      cs[-1] = cs[-1] + '.' + ext
      self.class.new(cs)
    end

    def without_ext
      cs = self.components.dup
      cs[-1] = cs[-1].sub(/\.\w+$/, '')
      self.class.new(cs)
    end

    def in_dir
      base = self.without_ext.add_component('index')
      if self.extension
        base.with_ext(self.extension)
      else
        base
      end
    end

    def +(string)
      self.to_s + string
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
