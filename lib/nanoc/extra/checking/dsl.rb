# encoding: utf-8

module Nanoc::Extra::Checking

  class DSL

    attr_reader :deploy_checks

    def self.from_file(filename)
      dsl = new
      dsl.instance_eval File.read(filename)
      dsl
    end

    def initialize
      @deploy_checks = []
    end

    def check(identifier, &block)
      klass = Class.new(::Nanoc::Extra::Checking::Check)
      klass.send(:define_method, :run, &block)
      klass.send(:identifier, identifier)
    end

    def deploy_check(*identifiers)
      identifiers.each { |i| @deploy_checks << i }
    end

  end

end
