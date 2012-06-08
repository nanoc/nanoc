# encoding: utf-8

usage       'validate-css [options]'
aliases     :validate_css, :vcss
summary     'validate the site’s CSS'
description <<-EOS
Validates the site’s CSS files.
EOS

module Nanoc::CLI::Commands

  class ValidateCSS < ::Nanoc::CLI::CommandRunner

    def run
      require_site
      validator = ::Nanoc::Extra::Validators::W3C.new(site.config[:output_dir], [ :css ])
      validator.run
    end

  end

end

runner Nanoc::CLI::Commands::ValidateCSS
