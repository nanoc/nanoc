# frozen_string_literal: true

module Nanoc
  module Checking
    module Checks
      # @api private
      class Stale < ::Nanoc::Checking::Check
        identifier :stale

        def run
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
          @_item_rep_paths ||=
            Set.new(
              @items
                .flat_map(&:reps)
                .map(&:_unwrap)
                .flat_map(&:raw_paths)
                .flat_map(&:values)
                .flatten,
            )
        end

        def pruner
          @_pruner ||= begin
            exclude_config = @config.fetch(:prune, {}).fetch(:exclude, [])
            # FIXME: specifying reps this way is icky
            reps = Nanoc::Core::ItemRepRepo.new
            Nanoc::Core::Pruner.new(@config._unwrap, reps, exclude: exclude_config)
          end
        end
      end
    end
  end
end
