module Nanoc
  module Int
    # Abstract content.
    #
    # The filename is the full filename on the default filesystem. It can be
    # nil. It is used by filters such as Sass, which look up items on the
    # filesystem.
    #
    # @abstract
    #
    # @api private
    class Content
      # @return [String, nil]
      attr_reader :filename

      # @param [String, nil] filename
      def initialize(filename)
        if filename && Pathname.new(filename).relative?
          raise ArgumentError, 'Content filename is not absolute'
        end

        @filename = filename
      end

      def freeze
        super
        @filename.freeze
      end

      # @param [String, Proc] content The uncompiled item content (if it is textual
      #   content) or the path to the filename containing the content (if this
      #   is binary content).
      #
      # @param [Boolean] binary Whether or not this item is binary
      #
      # @param [String] filename Absolute path to the file containing this
      #   content (if any)
      def self.create(content, binary: false, filename: nil)
        if content.nil?
          raise ArgumentError, 'Cannot create nil content'
        elsif content.is_a?(Nanoc::Int::Content)
          content
        elsif binary
          Nanoc::Int::BinaryContent.new(content)
        else
          Nanoc::Int::TextualContent.new(content, filename: filename)
        end
      end

      # @abstract
      #
      # @return [Boolean]
      def binary?
        raise NotImplementedError
      end
    end

    # @api private
    class TextualContent < Content
      # @return [String]
      def string
        @string.value
      end

      def initialize(string, filename: nil)
        super(filename)
        @string = Nanoc::Int::LazyValue.new(string)
      end

      def freeze
        super
        @string.freeze
      end

      def binary?
        false
      end

      def marshal_dump
        [filename, string]
      end

      def marshal_load(array)
        @filename = array[0]
        @string = Nanoc::Int::LazyValue.new(array[1])
      end
    end

    # @api private
    class BinaryContent < Content
      def binary?
        true
      end
    end
  end
end
