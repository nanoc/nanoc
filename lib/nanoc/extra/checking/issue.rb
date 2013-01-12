# encoding: utf-8

module Nanoc::Extra::Checking

  class Issue

    attr_reader :description
    attr_reader :subject
    attr_reader :check_class

    def initialize(desc, subject, check_class)
      @description   = desc
      @subject       = subject
      @check_class = check_class
    end

  end

end
