# encoding: utf-8

module Nanoc

  class Identifier

    attr_reader :components

    def self.from_string(string)
      components = string.split('/').reject { |c| c.empty? }
      components.freeze
      self.new(components)
    end

    def initialize(components)
      unless components.frozen?
        raise ArgumentError, "Nanoc::Identifier components must be frozen"
      end

      @components = components
    end

    def parent
      if self.components.empty?
        nil
      else
        parent_components = self.components[0..-2]
        parent_components.freeze
        self.class.new(parent_components)
      end
    end

    # FIXME ugly
    def +(string)
      self.to_s + string
    end

    # FIXME ugly
    def chop
      self.to_s.chop
    end

    def hash
      self.components.hash
    end

    def eql?(other)
      # TODO compare components, not strings
      self.to_s == other.to_s
    end

    def ==(other)
      self.eql?(other)
    end

    # TODO implement === so comparison with string is possible

    def inspect
      "<#{self.class} #{self.to_s.inspect}>"
    end

    def to_s
      if self.components.empty?
        '/'
      else
        '/' + self.components.join('/') + '/'
      end
    end

  end

end
