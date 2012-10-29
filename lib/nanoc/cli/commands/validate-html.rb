# encoding: utf-8

usage       'validate-html [options]'
aliases     :validate_html, :vhtml
summary     'validate the site’s HTML'
be_hidden
description <<-EOS
Validates the site’s HTML files.
EOS

module Nanoc::CLI::Commands

  class ValidateHTML < ::Nanoc::CLI::CommandRunner

    def run
      Nanoc::CLI.run %w( check html )
    end

  end

end

runner Nanoc::CLI::Commands::ValidateHTML
