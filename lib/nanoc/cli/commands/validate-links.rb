# encoding: utf-8

usage       'validate-links [options]'
aliases     :validate_links, :vlink
summary     'validate links in site'
be_hidden
description "
Validates the site’s links. By default, both internal and external links will be checked.
"

flag   :i, :internal, 'validate internal links only'
flag   :e, :external, 'validate external links only'

module Nanoc::CLI::Commands

  class ValidateLinks < ::Nanoc::CLI::CommandRunner

    def run
      warn 'The `validate-links` command is deprecated. Please use the new `check` command instead.'

      checks = []
      checks << 'ilinks' if options[:internal]
      checks << 'elinks' if options[:external]
      Nanoc::CLI.run [ 'check', checks ].flatten
    end

  end

end

runner Nanoc::CLI::Commands::ValidateLinks
