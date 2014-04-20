# encoding: utf-8

require 'singleton'

module Nanoc::Extra

  class JRubyNokogiriWarner

    include Singleton

    TEXT = <<EOS
--------------------------------------------------------------------------------
Caution:

Nokogiri on JRuby has severe bugs that prevent it from producing correct results
in many cases. For example, the nanoc test cases revealed the following bugs:

- http://github.com/sparklemotion/nokogiri/issues/1077
- http://github.com/sparklemotion/nokogiri/issues/1078
- http://github.com/sparklemotion/nokogiri/issues/1079
- http://github.com/sparklemotion/nokogiri/issues/1080
- http://github.com/sparklemotion/nokogiri/issues/1081
- http://github.com/sparklemotion/nokogiri/issues/1084

Because of these issues, we advise against using Nokogiri on JRuby. If you need
XML parsing functionality, consider not using JRuby for the time being.
--------------------------------------------------------------------------------
EOS

    def self.check_and_warn
      instance.check_and_warn
    end

    def initialize
      @warned = false
    end

    def check_and_warn
      return if !defined?(RUBY_ENGINE)
      return if RUBY_ENGINE != 'jruby'
      return if @warned

      $stderr.puts TEXT
      @warned = true
    end

  end

end
