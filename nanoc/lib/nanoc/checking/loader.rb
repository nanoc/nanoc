# frozen_string_literal: true

module Nanoc::Checking
  # @api private
  class Loader
    CHECKS_FILENAMES = ['Checks', 'Checks.rb', 'checks', 'checks.rb'].freeze

    def run
      dsl
    end

    def deploy_checks
      dsl.deploy_checks
    end

    private

    def dsl_present?
      checks_filename && File.file?(checks_filename)
    end

    def dsl
      @dsl ||=
        if dsl_present?
          Nanoc::Checking::DSL.from_file(checks_filename)
        else
          Nanoc::Checking::DSL.new
        end
    end

    def checks_filename
      @_checks_filename ||= CHECKS_FILENAMES.find { |f| File.file?(f) }
    end
  end
end
