# encoding: utf-8

module Nanoc::Extra::Checking

  class Issue

    attr_reader :description
    attr_reader :subject
    attr_reader :checker_class

    def initialize(desc, subject, checker_class)
      @description   = desc
      @subject       = subject
      @checker_class = checker_class
    end

  end

end
