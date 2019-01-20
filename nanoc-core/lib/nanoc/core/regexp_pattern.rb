# frozen_string_literal: true

module Nanoc
  module Core
    class RegexpPattern < Pattern
      contract Regexp => C::Any
      def initialize(regexp)
        @regexp = regexp
      end

      contract C::Or[Nanoc::Core::Identifier, String] => C::Bool
      def match?(identifier)
        (identifier.to_s =~ @regexp) != nil
      end

      contract C::Or[Nanoc::Core::Identifier, String] => C::Maybe[C::ArrayOf[String]]
      def captures(identifier)
        matches = @regexp.match(identifier.to_s)
        matches&.captures
      end

      contract C::None => String
      def to_s
        @regexp.to_s
      end
    end
  end
end
