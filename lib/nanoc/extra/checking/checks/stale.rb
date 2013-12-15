# encoding: utf-8

module Nanoc::Extra::Checking::Checks

  class Stale < ::Nanoc::Extra::Checking::Check

    def run
      require 'set'

      item_rep_paths = Set.new(@site.items.map { |i| i.reps }.flatten.map { |r| r.raw_path })

      output_filenames.each do |f|
        next if pruner.filename_excluded?(f)
        if !item_rep_paths.include?(f)
          add_issue(
            'file without matching item',
            :subject  => f)
        end
      end
    end

  protected

    def pruner
      exclude_config = @site.config.fetch(:prune, {}).fetch(:exclude, [])
      @pruner ||= Nanoc::Extra::Pruner.new(@site, :exclude => exclude_config)
    end

  end

end
