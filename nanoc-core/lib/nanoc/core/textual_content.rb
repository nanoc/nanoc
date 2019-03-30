# frozen_string_literal: true

module Nanoc
  module Core
    class TextualContent < Content
      contract C::Or[String, Proc], C::KeywordArgs[filename: C::Optional[C::Maybe[String]]] => C::Any
      def initialize(string, filename: nil)
        super(filename)
        @string = Nanoc::Core::LazyValue.new(string)
      end

      contract C::None => String
      def string
        @string.value
      end

      contract C::None => self
      def freeze
        super
        @string.freeze
        self
      end

      contract C::None => C::Bool
      def binary?
        false
      end

      contract C::None => Array
      def marshal_dump
        [filename, string]
      end

      contract Array => C::Any
      def marshal_load(array)
        @filename = array[0]
        @string = Nanoc::Core::LazyValue.new(array[1])
      end
    end
  end
end
