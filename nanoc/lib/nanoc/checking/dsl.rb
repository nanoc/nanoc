# frozen_string_literal: true

module Nanoc::Checking
  # @api private
  class DSL
    # FIXME: do not expose @enabled_checks
    attr_reader :enabled_checks

    def self.from_file(filename)
      dsl = new
      absolute_filename = File.expand_path(filename)
      dsl.instance_eval(File.read(filename), absolute_filename)
      dsl
    end

    def initialize
      @enabled_checks = []
    end

    def check(identifier, &block)
      klass = Class.new(::Nanoc::Checking::Check)
      klass.send(:define_method, :run, &block)
      klass.send(:identifier, identifier)
    end

    def deploy_check(*identifiers)
      identifiers.each { |i| @enabled_checks << i }
    end
  end
end
