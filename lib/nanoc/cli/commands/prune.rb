# encoding: utf-8

usage       'prune'
summary     'remove files not managed by nanoc from the output directory'
description <<-EOS
Find all files in the output directory that do not correspond to an item
managed by nanoc and remove them. Since this is a hazardous operation, an
additional `--yes` flag is needed as confirmation.

Also see the `auto_prune` configuration option in `nanoc.yaml` (`config.yaml`
for older nanoc sites), which will automatically prune after compilation.
EOS

flag :y, :yes,       'confirm deletion'
flag :n, :'dry-run', 'print files to be deleted instead of actually deleting them'

module Nanoc::CLI::Commands

  class Prune < ::Nanoc::CLI::CommandRunner

    def run
      self.load_site

      params = { :exclude => self.prune_config_exclude }
      if options.has_key?(:yes)
        # do not adjust params
      elsif options.has_key?(:'dry-run')
        params[:dry_run] = true
      else
        $stderr.puts "WARNING: Since the prune command is a destructive command, it requires an additional --yes flag in order to work."
        $stderr.puts
        $stderr.puts "Please ensure that the output directory does not contain any files (such as images or stylesheets) that are necessary but are not managed by nanoc. If you want to get a list of all files that would be removed, pass --dry-run."
        exit 1
      end

      self.pruner_class.new(self.site, params).run
    end

  protected

    def pruner_class
      compiler = Nanoc::Compiler.new(self.site)
      identifier = compiler.item_rep_writer.class.identifier
      Nanoc::Extra::Pruner.named(identifier)
    end

    def prune_config
      self.site.config.fetch(:prune, {})
    end

    def prune_config_exclude
      self.prune_config.fetch(:exclude, {})
    end

  end

end

runner Nanoc::CLI::Commands::Prune
