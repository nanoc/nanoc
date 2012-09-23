# encoding: utf-8

module Nanoc::Extra::Checking

  class Issue

    SEVERITIES = [ :ok, :error ]

    attr_reader :description
    attr_reader :subject
    attr_reader :severity
    attr_reader :checker_class

    def initialize(desc, subject, severity, checker_class)
      @description   = desc
      @subject       = subject
      @severity      = severity
      @checker_class = checker_class

      unless SEVERITIES.include?(severity)
        raise ArgumentError, "Invalid severity given: was #{severity.inspect} but expected one of #{SEVERITIES.map { |s| s.inspect }.join(', ')}"
      end 
    end

  end

end
