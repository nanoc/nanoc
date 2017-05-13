# frozen_string_literal: true

module Nanoc
  class Identifier
    include Comparable
    include Nanoc::Int::ContractsSupport

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

    contract C::Any => self
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

    contract String, C::KeywordArgs[type: C::Optional[Symbol]] => C::Any
    def initialize(string, type: :full)
      @type = type

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

    contract C::Any => C::Bool
    def ==(other)
      case other
      when Nanoc::Identifier, String
        to_s == other.to_s
      else
        false
      end
    end

    contract C::Any => C::Bool
    def eql?(other)
      other.is_a?(self.class) && to_s == other.to_s
    end

    contract C::None => C::Num
    def hash
      self.class.hash ^ to_s.hash
    end

    contract C::Any => C::Maybe[C::Num]
    def =~(other)
      Nanoc::Int::Pattern.from(other).match?(to_s) ? 0 : nil
    end

    contract C::Any => C::Num
    def <=>(other)
      to_s <=> other.to_s
    end

    contract C::None => C::Bool
    # Whether or not this is a full identifier (i.e.includes the extension).
    def full?
      @type == :full
    end

    contract C::None => C::Bool
    # Whether or not this is a legacy identifier (i.e. does not include the extension).
    def legacy?
      @type == :legacy
    end

    contract C::None => String
    # @return [String]
    def chop
      to_s.chop
    end

    contract String => String
    # @return [String]
    def +(other)
      to_s + other
    end

    contract String => self
    # @return [Nanoc::Identifier]
    def prefix(string)
      if string !~ /\A\//
        raise InvalidPrefixError.new(string)
      end
      Nanoc::Identifier.new(string.sub(/\/+\z/, '') + @string, type: @type)
    end

    contract C::None => String
    # The identifier, as string, with the last extension removed
    def without_ext
      unless full?
        raise UnsupportedLegacyOperationError
      end

      extname = File.extname(@string)

      if !extname.empty?
        @string[0..-extname.size - 1]
      else
        @string
      end
    end

    contract C::None => C::Maybe[String]
    # The extension, without a leading dot
    def ext
      unless full?
        raise UnsupportedLegacyOperationError
      end

      s = File.extname(@string)
      s && s[1..-1]
    end

    contract C::None => String
    # The identifier, as string, with all extensions removed
    def without_exts
      extname = exts.join('.')
      if !extname.empty?
        @string[0..-extname.size - 2]
      else
        @string
      end
    end

    contract C::None => C::ArrayOf[String]
    # The list of extensions, without a leading dot
    def exts
      unless full?
        raise UnsupportedLegacyOperationError
      end

      s = File.basename(@string)
      s ? s.split('.', -1).drop(1) : []
    end

    contract C::None => C::ArrayOf[String]
    def components
      res = to_s.split('/')
      if res.empty?
        []
      else
        res[1..-1]
      end
    end

    contract C::None => String
    def to_s
      @string
    end

    contract C::None => String
    def to_str
      @string
    end

    contract C::None => String
    def inspect
      "<Nanoc::Identifier type=#{@type} #{to_s.inspect}>"
    end
  end
end
