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
        if filename && !filename.start_with?('/')
          raise ArgumentError, 'Content filename is not absolute'
        end

        @filename = filename
      end

      def freeze
        super
        @filename.freeze
      end

      # @param [String] content The uncompiled item content (if it is textual
      #   content) or the path to the filename containing the content (if this
      #   is binary content).
      #
      # @option params [Boolean] :binary (false) Whether or not this item is
      #   binary
      #
      # @option params [String] :filename (nil) Absolute path to the file
      #   containing this content (if any)
      def self.create(content, params = {})
        if content.nil?
          raise ArgumentError, 'Cannot create nil content'
        elsif content.is_a?(Nanoc::Int::Content)
          content
        elsif params.fetch(:binary, false)
          Nanoc::Int::BinaryContent.new(content)
        else
          Nanoc::Int::TextualContent.new(content, filename: params[:filename])
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
      attr_reader :string

      def initialize(string, params = {})
        super(params[:filename])
        @string = string
      end

      def freeze
        super
        @string.freeze
      end

      def binary?
        false
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
