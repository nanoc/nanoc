# frozen_string_literal: true

require 'singleton'

module Nanoc::Extra
  # @api private
  class JRubyNokogiriWarner
    include Singleton

    TEXT = <<~EOS
      --------------------------------------------------------------------------------
      Note:

      The behavior of Pure Java Nokogiri differs from the Nokogiri used on the
      standard Ruby interpreter (MRI) due to differences in underlying libraries.

      These sometimes problematic behavioral differences can cause Nanoc filters not
      to function properly, if at all. If you need reliable (X)HTML and XML handling
      functionality, consider not using Nokogiri on JRuby for the time being.

      These issues are being worked on both from the Nokogiri and the Nanoc side. Keep
      your Nokogiri and Nanoc versions up to date!

      For details, see https://github.com/nanoc/nanoc/pull/422.
      --------------------------------------------------------------------------------
EOS

    def self.check_and_warn
      instance.check_and_warn
    end

    def initialize
      @warned = false
    end

    def check_and_warn
      return unless defined?(RUBY_ENGINE)
      return if RUBY_ENGINE != 'jruby'
      return if @warned

      $stderr.puts TEXT
      @warned = true
    end
  end
end
