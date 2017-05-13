# frozen_string_literal: true

usage 'prune'
summary 'remove files not managed by Nanoc from the output directory'
description <<~EOS
  Find all files in the output directory that do not correspond to an item
  managed by Nanoc and remove them. Since this is a hazardous operation, an
  additional `--yes` flag is needed as confirmation.

  Also see the `auto_prune` configuration option in `nanoc.yaml` (`config.yaml`
  for older Nanoc sites), which will automatically prune after compilation.
EOS

flag :y, :yes,       'confirm deletion'
flag :n, :'dry-run', 'print files to be deleted instead of actually deleting them'

module Nanoc::CLI::Commands
  class Prune < ::Nanoc::CLI::CommandRunner
    def run
      load_site(preprocess: true)
      site.compiler.build_reps

      if options.key?(:yes)
        Nanoc::Pruner.new(site.config, site.compiler.reps, exclude: prune_config_exclude).run
      elsif options.key?(:'dry-run')
        Nanoc::Pruner.new(site.config, site.compiler.reps, exclude: prune_config_exclude, dry_run: true).run
      else
        $stderr.puts 'WARNING: Since the prune command is a destructive command, it requires an additional --yes flag in order to work.'
        $stderr.puts
        $stderr.puts 'Please ensure that the output directory does not contain any files (such as images or stylesheets) that are necessary but are not managed by Nanoc. If you want to get a list of all files that would be removed, pass --dry-run.'
        exit 1
      end
    end

    protected

    def prune_config
      site.config[:prune] || {}
    end

    def prune_config_exclude
      prune_config[:exclude] || {}
    end
  end
end

runner Nanoc::CLI::Commands::Prune
