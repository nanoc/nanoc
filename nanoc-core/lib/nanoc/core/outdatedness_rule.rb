# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class OutdatednessRule
      include Nanoc::Core::ContractsSupport
      include Singleton

      def self.affects_path?
        @affects_path
      end

      def self.affects_attributes?
        @affects_attributes
      end

      def self.affects_compiled_content?
        @affects_compiled_content
      end

      def self.affects_props(*names)
        @affects_raw_content = false
        @affects_attributes = false
        @affects_compiled_content = false
        @affects_path = false

        names.each do |name|
          case name
          when :raw_content
            @affects_raw_content = true
          when :attributes
            @affects_attributes = true
          when :compiled_content
            @affects_compiled_content = true
          when :path
            @affects_path = true
          end
        end
      end

      def self.affects_raw_content?
        @affects_raw_content
      end

      def call(obj, outdatedness_checker)
        Nanoc::Core::Instrumentor.call(:outdatedness_rule_ran, self.class) do
          apply(obj, outdatedness_checker)
        end
      end

      def apply(_obj, _outdatedness_checker)
        raise NotImplementedError.new('Nanoc::Core::OutdatednessRule subclasses must implement #apply')
      end

      contract C::None => String
      def inspect
        "#{self.class.name}(#{reason})"
      end
    end
  end
end
