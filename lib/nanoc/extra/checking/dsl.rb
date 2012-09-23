# encoding: utf-8

module Nanoc::Extra::Checking

  class DSL

    attr_reader :deploy_checks

    def self.from_file(filename)
      dsl = self.new
      dsl.instance_eval File.read(filename)
      dsl
    end

    def initialize
      @deploy_checks = []
    end

    def check(identifier, description, &block)
      klass = Class.new(::Nanoc::Extra::Checking::Checker)
      klass.send(:define_method, :run, &block)
      klass.send(:identifier, identifier)
    end

    def deploy_check(*identifiers)
      identifiers.each { |i| @deploy_checks << i }
    end

  end

end
