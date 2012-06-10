# encoding: utf-8

usage       'validate-css [options]'
aliases     :validate_css, :vcss
summary     'validate the site’s CSS'
be_hidden
description <<-EOS
Validates the site’s CSS files.
EOS

module Nanoc::CLI::Commands

  class ValidateCSS < ::Nanoc::CLI::CommandRunner

    def run
      Nanoc::CLI.run %w( check css )
    end

  end

end

runner Nanoc::CLI::Commands::ValidateCSS
