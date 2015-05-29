module Nanoc::Extra::Checking::Checks
  # @api private
  class Stale < ::Nanoc::Extra::Checking::Check
    def run
      require 'set'

      item_rep_paths = Set.new(@items.map(&:reps).flatten.map(&:raw_path))

      output_filenames.each do |f|
        next if pruner.filename_excluded?(f)
        next if item_rep_paths.include?(f)

        add_issue(
          'file without matching item',
          subject: f)
      end
    end

    protected

    def pruner
      exclude_config = @config.fetch(:prune, {}).fetch(:exclude, [])
      @pruner ||= Nanoc::Extra::Pruner.new(@site, exclude: exclude_config)
    end
  end
end
