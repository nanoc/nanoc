# encoding: utf-8

usage       'validate-links [options]'
aliases     :validate_links, :vlink
summary     'validate links in site'
be_hidden
description <<-EOS
Validates the site’s links. By default, both internal and external links will be checked.
EOS

flag   :i, :internal, 'validate internal links only'
flag   :e, :external, 'validate external links only'

module Nanoc::CLI::Commands

  class ValidateLinks < ::Nanoc::CLI::CommandRunner

    def run
      checkers = []
      checkers << 'ilinks' if options[:internal]
      checkers << 'elinks' if options[:external]
      Nanoc::CLI.run [ 'check', checkers ].flatten
    end

  end

end

runner Nanoc::CLI::Commands::ValidateLinks
