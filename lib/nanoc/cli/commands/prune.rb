# encoding: utf-8

usage       'prune'
summary     'remove files not managed by nanoc from the output directory'
description <<-EOS
Find all files in the output directory that do not correspond to an item
managed by nanoc and remove them. Since this is a hazardous operation, an
additional --yes flag is needed as confirmation.

Also see the auto_prune site configuration option in config.yaml, which will
automatically prune after compilation.
EOS

flag :y, :yes,       'confirm deletion'
flag :n, :'dry-run', 'print files to be deleted instead of actually deleting them'

module Nanoc::CLI::Commands

  class Prune < ::Nanoc::CLI::CommandRunner

    def run
      require_site

      if options.has_key?(:yes)
        Nanoc::Extra::Pruner.new(self.site, :exclude => self.prune_config_exclude).run
      elsif options.has_key?(:'dry-run')
        Nanoc::Extra::Pruner.new(self.site, :exclude => self.prune_config_exclude, :dry_run => true).run
      else
        $stderr.puts "WARNING: Since the prune command is a destructive command, it requires an additional --yes flag in order to work."
        $stderr.puts
        $stderr.puts "Please ensure that the output directory does not contain any files (such as images or stylesheets) that are necessary but are not managed by nanoc. If you want to get a list of all files that would be removed, pass --dry-run."
        exit 1
      end
    end

  protected

    def prune_config
      self.site.config[:prune] || {}
    end

    def prune_config_exclude
      self.prune_config[:exclude] || {}
    end
    
  end

end

runner Nanoc::CLI::Commands::Prune
