# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class OutdatednessRule
      include Nanoc::Core::ContractsSupport
      include Singleton

      def call(obj, outdatedness_checker)
        Nanoc::Core::Instrumentor.call(:outdatedness_rule_ran, self.class) do
          apply(obj, outdatedness_checker)
        end
      end

      def apply(_obj, _outdatedness_checker)
        raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement #apply')
      end

      contract C::None => String
      def inspect
        "#{self.class.name}(#{reason})"
      end

      def self.affects_props(*names)
        @affected_props = Set.new(names)
      end

      def self.affected_props
        @affected_props
      end
    end
  end
end
