# encoding: utf-8

module Nanoc

  # Used for identifying items and layouts.
  #
  # An identifier resembles a filesystem path quite closely: it is a list of
  # strings separated by slashes. The last component can have an extension.
  #
  # Some examples of identifiers:
  #
  #     /doc/tutorial.md
  #     /index.html
  class Identifier

    # @return [Array<String>] The components of this identifier.
    attr_reader :components

    # Creates an identifier from a string.
    #
    # @param [String] string The string to build an identifier from. It should
    #   be in the format "/foo/bar.ext".
    #
    # @return [Nanoc::Identifier]
    def self.from_string(string)
      components = string.split('/').reject { |c| c.empty? }
      self.new(components)
    end

    # @param [Array<String>] components
    def initialize(components)
      @components = components

      @components.freeze
      @components.each { |c| c.freeze }
    end

    # @return [String] The string representation of this identifier, starting
    #   with a slash followed by all components separated by a slash
    #
    # @example
    #
    #   Nanoc::Identifier.new(%w( foo bar index.html )).to_s
    #   # => '/foo/bar/index.html'
    def to_s
      if self.components.empty?
        '/'
      else
        '/' + self.components.join('/')
      end
    end

    # @param [String] string The string to append
    #
    # @return [String] A new string containing the identifier as a string,
    #   followed by the given string
    def +(string)
      self.to_s + string
    end

    # @!group Creating new instances

    # @return [Nanoc::Identifier, nil] A copy of the identifier with the last
    #   component removed, or nil if the identifier has no components.
    #
    # @example
    #
    #   Nanoc::Identifier.from_string('/foo/bar.md').parent.to_s
    #   # => '/foo'
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

    # FIXME ugly
    def add_component(string)
      self.class.new(self.components + [ string ])
    end

    # @param [String] ext
    #
    # @return [Nanoc::Identifier] A new identifier with the given extension. If
    #   the identifier already had an extension, it is removed.
    def with_ext(ext)
      cs = self.without_ext.components.dup
      cs[-1] = cs[-1] + '.' + ext
      self.class.new(cs)
    end

    # @return [Nanoc::Identifier] A new identifier with the extension removed
    def without_ext
      cs = self.components.dup
      cs[-1] = cs[-1].sub(/\.\w+$/, '')
      self.class.new(cs)
    end

    # @return [Nanoc::Identifier] A new identifier with the extension removed,
    #   an 'index' component added, followed by the original extension
    #
    # @example
    #
    #   Nanoc::Identifier.from_string('/foo/bar.html').in_dir.to_s
    #   # => '/foo/bar/index.html'
    def in_dir
      base = self.without_ext.add_component('index')
      if self.extension
        base.with_ext(self.extension)
      else
        base
      end
    end

    # @!group Accessing

    # @return [String, nil] The extension, or nil if there is none
    def extension
      c = self.components[-1]
      idx = c.rindex('.')
      if idx
        c[idx+1..-1]
      else
        nil
      end
    end

    # @!group Testing

    # @param [Nanoc::Pattern] pattern
    #
    # @return [Boolean] true if the identifier matches the given pattern, false
    #   otherwise
    #
    # @example
    #
    #   identifier = Nanoc::Identifier.from_string('/foo/bar.md')
    #   pattern = Nanoc::Pattern.from('/foo/*.md')
    #   identifier.match?(pattern)
    #   # => true
    #
    # @example
    #
    #   identifier = Nanoc::Identifier.from_string('/foo/bar.md')
    #   pattern = Nanoc::Pattern.from('/articles/*.html')
    #   identifier.match?(pattern)
    #   # => false
    def match?(pattern)
      Nanoc::Pattern.from(pattern).match?(self.to_s)
    end

    # @!group Inherited

    # @see Object#hash
    def hash
      self.components.hash
    end

    # @see Object#eql?
    def eql?(other)
      self.to_s == other.to_s
    end

    # @see Object#==
    def ==(other)
      self.eql?(other)
    end

    # @see Object#<=>
    def <=>(other)
      self.to_s <=> other.to_s
    end

    # @see Object#inspect
    def inspect
      "<#{self.class} #{self.to_s.inspect}>"
    end

  end

end
