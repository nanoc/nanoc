# frozen_string_literal: true

module Nanoc
  module Core
    class Content
      include Nanoc::Core::ContractsSupport

      contract C::Or[self, String, Proc], C::KeywordArgs[binary: C::Optional[C::Bool], filename: C::Optional[C::Maybe[String]]] => self
      def self.create(content, binary: false, filename: nil)
        if content.nil?
          raise ArgumentError, 'Cannot create nil content'
        elsif content.is_a?(Nanoc::Core::Content)
          content
        elsif binary
          Nanoc::Core::BinaryContent.new(content)
        else
          Nanoc::Core::TextualContent.new(content, filename:)
        end
      end

      contract C::None => C::Maybe[String]
      attr_reader :filename

      contract C::Maybe[String] => C::Any
      def initialize(filename)
        if filename && Pathname.new(filename).relative?
          raise ArgumentError, "Content filename #{filename} is not absolute"
        end

        @filename = filename
      end

      contract C::None => self
      def freeze
        super
        @filename.freeze
        self
      end

      contract C::None => C::Bool
      def binary?
        raise NotImplementedError
      end

      contract C::None => C::Bool
      def textual?
        !binary?
      end
    end
  end
end
