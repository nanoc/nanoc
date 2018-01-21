# frozen_string_literal: true

module Nanoc::Checking
  # @api private
  class Loader
    CHECKS_FILENAMES = ['Checks', 'Checks.rb', 'checks', 'checks.rb'].freeze

    def initialize(config:)
      @config = config
    end

    def run
      dsl
    end

    def deploy_checks
      (deploy_checks_from_dsl + deploy_checks_from_config).uniq
    end

    private

    def dsl_present?
      checks_filename && File.file?(checks_filename)
    end

    def deploy_checks_from_dsl
      dsl.deploy_checks
    end

    def deploy_checks_from_config
      @config.fetch(:checking, {}).fetch(:deploy_checks, []).map(&:to_sym)
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
