module Nanoc
  class Identifier
    include Comparable

    # @api private
    class InvalidIdentifierError < ::Nanoc::Error
      def initialize(string)
        super("Invalid identifier (does not start with a slash): #{string.inspect}")
      end
    end

    # @api private
    class InvalidTypeError < ::Nanoc::Error
      def initialize(type)
        super("Invalid type for identifier: #{type.inspect} (can be :full or :legacy)")
      end
    end

    # @api private
    class InvalidPrefixError < ::Nanoc::Error
      def initialize(string)
        super("Invalid prefix (does not start with a slash): #{string.inspect}")
      end
    end

    # @api private
    class UnsupportedLegacyOperationError < ::Nanoc::Error
      def initialize
        super('Cannot use this method on legacy identifiers')
      end
    end

    # @api private
    class NonCoercibleObjectError < ::Nanoc::Error
      def initialize(obj)
        super("#{obj.inspect} cannot be converted into a Nanoc::Identifier")
      end
    end

    def self.from(obj)
      case obj
      when Nanoc::Identifier
        obj
      when String
        Nanoc::Identifier.new(obj)
      else
        raise NonCoercibleObjectError.new(obj)
      end
    end

    def initialize(string, params = {})
      @type = params.fetch(:type, :full)

      case @type
      when :legacy
        @string = "/#{string}/".gsub(/^\/+|\/+$/, '/').freeze
      when :full
        if string !~ /\A\//
          raise InvalidIdentifierError.new(string)
        end
        @string = string.dup.freeze
      else
        raise InvalidTypeError.new(@type)
      end
    end

    def ==(other)
      to_s == other.to_s
    end
    alias_method :eql?, :==

    def hash
      self.class.hash ^ to_s.hash
    end

    def =~(other)
      Nanoc::Int::Pattern.from(other).match?(to_s) ? 0 : nil
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # @return [Boolean] True if this is a full-type identifier (i.e. includes
    #   the extension), false otherwise
    def full?
      @type == :full
    end

    # @return [String]
    def chop
      to_s.chop
    end

    # @return [String]
    def +(other)
      to_s + other
    end

    # @return [Nanoc::Identifier]
    def prefix(string)
      if string !~ /\A\//
        raise InvalidPrefixError.new(@string)
      end
      Nanoc::Identifier.new(string.sub(/\/+\z/, '') + @string, type: @type)
    end

    # @return [String]
    def without_ext
      unless full?
        raise UnsupportedLegacyOperationError
      end

      extname = File.extname(@string)

      if extname.size > 0
        @string[0..-extname.size - 1]
      else
        @string
      end
    end

    # @return [String] The extension, without a leading dot.
    def ext
      unless full?
        raise UnsupportedLegacyOperationError
      end

      s = File.extname(@string)
      s && s[1..-1]
    end

    # @return [String]
    def without_exts
      extname = exts.join('.')
      if extname.size > 0
        @string[0..-extname.size - 2]
      else
        @string
      end
    end

    # @return [Array] List of extensions, without a leading dot.
    def exts
      unless full?
        raise UnsupportedLegacyOperationError
      end

      s = File.basename(@string)
      s ? s.split('.', -1).drop(1) : []
    end

    def to_s
      @string
    end

    def to_str
      @string
    end

    def inspect
      "<Nanoc::Identifier type=#{@type} #{to_s.inspect}>"
    end
  end
end
