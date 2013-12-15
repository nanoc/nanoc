# encoding: utf-8

usage       'validate-css [options]'
aliases     :validate_css, :vcss
summary     'validate the site’s CSS'
be_hidden
description "
Validates the site’s CSS files.
"

module Nanoc::CLI::Commands

  class ValidateCSS < ::Nanoc::CLI::CommandRunner

    def run
      warn 'The `validate-css` command is deprecated. Please use the new `check` command instead.'
      Nanoc::CLI.run %w( check css )
    end

  end

end

runner Nanoc::CLI::Commands::ValidateCSS
