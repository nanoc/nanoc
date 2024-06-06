# frozen_string_literal: true

module Nanoc
  module Checking
    # @api private
    class DSL
      def self.from_file(filename, enabled_checks:)
        dsl = new(enabled_checks:)
        absolute_filename = File.expand_path(filename)
        dsl.instance_eval(File.read(filename), absolute_filename)
        dsl
      end

      def initialize(enabled_checks:)
        @enabled_checks = enabled_checks
      end

      def check(identifier, &)
        klass = Class.new(::Nanoc::Checking::Check)
        klass.send(:define_method, :run, &)
        klass.send(:identifier, identifier)
      end

      def deploy_check(*identifiers)
        identifiers.each { |i| @enabled_checks << i }
      end
    end
  end
end
