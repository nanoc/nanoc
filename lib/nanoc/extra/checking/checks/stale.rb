module Nanoc::Extra::Checking::Checks
  # @api private
  class Stale < ::Nanoc::Extra::Checking::Check
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
            .flat_map(&:values),
        )
    end

    def pruner
      exclude_config = @config.fetch(:prune, {}).fetch(:exclude, [])
      @pruner ||= Nanoc::Extra::Pruner.new(@site, exclude: exclude_config)
    end
  end
end
