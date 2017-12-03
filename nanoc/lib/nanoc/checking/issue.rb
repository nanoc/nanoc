# frozen_string_literal: true

module Nanoc::Checking
  # @api private
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
