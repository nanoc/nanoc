# frozen_string_literal: true

module Nanoc
  module Core
    class Pattern
      include Nanoc::Core::ContractsSupport

      contract C::Any => self
      def self.from(obj)
        case obj
        when Nanoc::Core::StringPattern, Nanoc::Core::RegexpPattern
          obj
        when String
          Nanoc::Core::StringPattern.new(obj)
        when Regexp
          Nanoc::Core::RegexpPattern.new(obj)
        when Symbol
          Nanoc::Core::StringPattern.new(obj.to_s)
        else
          raise ArgumentError, "Do not know how to convert `#{obj.inspect}` into a Nanoc::Pattern"
        end
      end

      def initialize(_obj)
        raise NotImplementedError
      end

      def match?(_identifier)
        raise NotImplementedError
      end

      contract C::Any => C::Bool
      def ===(other)
        match?(other)
      end

      def captures(_identifier)
        raise NotImplementedError
      end
    end
  end
end
