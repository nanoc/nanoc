# encoding: utf-8

usage       'validate-links [options]'
aliases     :validate_links, :vlink
summary     'validate links in site'
description <<-EOS
Validates the site’s links. By default, both internal and external links will be checked.
EOS

flag   :i, :internal, 'validate internal links only'
flag   :e, :external, 'validate external links only'

module Nanoc::CLI::Commands

  class ValidateLinks < ::Nanoc::CLI::CommandRunner

    def run
      require_site

      dir             = site.config[:output_dir]
      index_filenames = site.config[:index_filenames]

      validator = ::Nanoc::Extra::Validators::Links.new(
        dir,
        index_filenames,
        :internal => (options[:external] ? false : true),
        :external => (options[:internal] ? false : true))
      validator.run
    end

  end

end

runner Nanoc::CLI::Commands::ValidateLinks
