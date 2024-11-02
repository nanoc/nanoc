# frozen_string_literal: true

module Nanoc
  module Checking
    # @api private
    class Loader
      CHECKS_FILENAMES = ['Checks', 'Checks.rb', 'checks', 'checks.rb'].freeze

      def initialize(config:)
        @config = config
      end

      def run
        dsl
      end

      def enabled_checks
        (enabled_checks_from_dsl + enabled_checks_from_config).uniq
      end

      private

      def dsl_present?
        checks_filename && File.file?(checks_filename)
      end

      def enabled_checks_from_dsl
        dsl
        @enabled_checks_from_dsl
      end

      def enabled_checks_from_config
        @config.fetch(:checking, {}).fetch(:enabled_checks, []).map(&:to_sym)
      end

      def dsl
        @enabled_checks_from_dsl ||= []

        @_dsl ||=
          if dsl_present?
            Nanoc::Checking::DSL.from_file(checks_filename, enabled_checks: @enabled_checks_from_dsl)
          else
            Nanoc::Checking::DSL.new(enabled_checks: @enabled_checks_from_dsl)
          end
      end

      def checks_filename
        @_checks_filename ||= CHECKS_FILENAMES.find { |f| File.file?(f) }
      end
    end
  end
end
