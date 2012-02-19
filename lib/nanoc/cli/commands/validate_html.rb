# encoding: utf-8

usage       'validate_html [options]'
aliases     [ 'vhtml' ]
summary     'validate the site’s HTML'
description <<-EOS
Validates the site’s HTML files.
EOS

module Nanoc::CLI::Commands

  class ValidateHTML < ::Nanoc::CLI::CommandRunner

    def run
      require_site
      validator = ::Nanoc::Extra::Validators::W3C.new(site.config[:output_dir], [ :html ])
      validator.run
    end

  end

end

runner Nanoc::CLI::Commands::ValidateHTML
