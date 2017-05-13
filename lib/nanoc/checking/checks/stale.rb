# frozen_string_literal: true

module Nanoc::Checking::Checks
  # @api private
  class Stale < ::Nanoc::Checking::Check
    identifier :stale

    def run
      require 'set'

      output_filenames.each do |f|
        next if pruner.filename_excluded?(f)
        next if item_rep_paths.include?(f)

        add_issue(
          'file without matching item',
          subject: f,
        )
      end
    end

    protected

    def item_rep_paths
      @item_rep_paths ||=
        Set.new(
          @items
            .flat_map(&:reps)
            .map(&:unwrap)
            .flat_map(&:raw_paths)
            .flat_map(&:values)
            .flatten,
        )
    end

    def pruner
      exclude_config = @config.fetch(:prune, {}).fetch(:exclude, [])
      # FIXME: reps=nil is icky
      @pruner ||= Nanoc::Pruner.new(@config, nil, exclude: exclude_config)
    end
  end
end
