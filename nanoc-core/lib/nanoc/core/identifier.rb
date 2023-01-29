# frozen_string_literal: true

module Nanoc
  module Core
    class Identifier
      include Comparable
      include Nanoc::Core::ContractsSupport

      class InvalidIdentifierError < ::Nanoc::Core::Error
        def initialize(string)
          super("Invalid identifier (does not start with a slash): #{string.inspect}")
        end
      end

      class InvalidFullIdentifierError < ::Nanoc::Core::Error
        def initialize(string)
          super("Invalid full identifier (ends with a slash): #{string.inspect}")
        end
      end

      class InvalidTypeError < ::Nanoc::Core::Error
        def initialize(type)
          super("Invalid type for identifier: #{type.inspect} (can be :full or :legacy)")
        end
      end

      class InvalidPrefixError < ::Nanoc::Core::Error
        def initialize(string)
          super("Invalid prefix (does not start with a slash): #{string.inspect}")
        end
      end

      class UnsupportedLegacyOperationError < ::Nanoc::Core::Error
        def initialize
          super('Cannot use this method on legacy identifiers')
        end
      end

      class NonCoercibleObjectError < ::Nanoc::Core::Error
        def initialize(obj)
          super("#{obj.inspect} cannot be converted into a Nanoc::Core::Identifier")
        end
      end

      contract C::Any => self
      def self.from(obj)
        case obj
        when Nanoc::Core::Identifier
          obj
        when String
          Nanoc::Core::Identifier.new(obj)
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
          raise InvalidIdentifierError.new(string) if string !~ /\A\//
          raise InvalidFullIdentifierError.new(string) if string =~ /\/\z/

          @string = string.dup.freeze
        else
          raise InvalidTypeError.new(@type)
        end
      end

      contract C::Any => C::Bool
      def ==(other)
        case other
        when Nanoc::Core::Identifier, String
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
        [self.class, to_s].hash
      end

      contract C::Any => C::Maybe[C::Num]
      def =~(other)
        Nanoc::Core::Pattern.from(other).match?(to_s) ? 0 : nil
      end

      contract C::Any => C::Bool
      def match?(other)
        Nanoc::Core::Pattern.from(other).match?(to_s)
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
      # @return [Nanoc::Core::Identifier]
      def prefix(string)
        unless /\A\//.match?(string)
          raise InvalidPrefixError.new(string)
        end

        Nanoc::Core::Identifier.new(string.sub(/\/+\z/, '') + @string, type: @type)
      end

      contract C::None => String
      # The identifier, as string, with the last extension removed
      def without_ext
        unless full?
          raise UnsupportedLegacyOperationError
        end

        extname = File.extname(@string)

        if extname.empty?
          @string
        else
          @string[0..-extname.size - 1]
        end
      end

      contract C::None => C::Maybe[String]
      # The extension, without a leading dot
      def ext
        unless full?
          raise UnsupportedLegacyOperationError
        end

        s = File.extname(@string)
        s && s[1..]
      end

      contract C::None => String
      # The identifier, as string, with all extensions removed
      def without_exts
        extname = exts.join('.')
        if extname.empty?
          @string
        else
          @string[0..-extname.size - 2]
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
          res[1..]
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
        "<Nanoc::Core::Identifier type=#{@type} #{to_s.inspect}>"
      end
    end
  end
end
