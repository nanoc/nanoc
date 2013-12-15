# encoding: utf-8

usage       'validate-html [options]'
aliases     :validate_html, :vhtml
summary     'validate the site’s HTML'
be_hidden
description "
Validates the site’s HTML files.
"

module Nanoc::CLI::Commands

  class ValidateHTML < ::Nanoc::CLI::CommandRunner

    def run
      warn 'The `validate-html` command is deprecated. Please use the new `check` command instead.'
      Nanoc::CLI.run %w( check html )
    end

  end

end

runner Nanoc::CLI::Commands::ValidateHTML
