# frozen_string_literal: true

module Nanoc
  module Core
    class StringPattern < Pattern
      MATCH_OPTS = File::FNM_PATHNAME | File::FNM_EXTGLOB

      contract String => C::Any
      def initialize(string)
        @string = string
      end

      contract C::Or[Nanoc::Core::Identifier, String] => C::Bool
      def match?(identifier)
        File.fnmatch(@string, identifier.to_s, MATCH_OPTS)
      end

      contract C::Or[Nanoc::Core::Identifier, String] => nil
      def captures(_identifier)
        nil
      end

      contract C::None => String
      def to_s
        @string
      end
    end
  end
end
